module KnifeSoloDataBag

  class SoloDataBagCreate < Chef::Knife

    require 'chef/knife/helpers'
    require 'fileutils'

    include KnifeSoloDataBag::Helpers

    banner 'knife solo data bag create BAG [ITEM] (options)'
    category 'solo data bag'

    attr_reader :bag_name, :item_name

    option :secret,
           :short => '-s SECRET',
           :long  => '--secret SECRET',
           :description => 'The secret key to use to encrypt data bag item values'

    option :secret_file,
           :long  => '--secret-file SECRET_FILE',
           :description => 'A file containing the secret key to use to encrypt data bag item values'

    def run
      @bag_name, @item_name = @name_args
      ensure_valid_arguments
      create_bag_directory
      create_bag_item if item_name
    end

    private
    def bag_item_content(content)
      return content unless should_be_encrypted?
      Chef::EncryptedDataBagItem.encrypt_data_bag_item content, secret_key
    end

    def create_bag_directory
      FileUtils.mkdir_p bag_path unless File.exists? bag_path
    end

    def create_bag_item
      create_object({'id' => item_name}, "data_bag_item[#{item_name}]") do |output|
        item = Chef::DataBagItem.from_hash bag_item_content(output)
        item.data_bag bag_name
        persist_bag_item item
      end
    end

    def ensure_valid_arguments
      validate_bag_name_provided
      validate_bags_path_exists
      validate_multiple_secrets_were_not_provided
    end

    def persist_bag_item(item)
      File.open bag_item_path, 'w' do |f|
        f.write item.to_json
      end
    end

  end

end
