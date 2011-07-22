module Tire
  class Attachment
    def initialize(file_or_hash)
      case file_or_hash
        when File
          @file = file_or_hash
        when Hash
          @filename     = file_or_hash[:_name]         || file_or_hash['_name']
          @content_type = file_or_hash[:_content_type] || file_or_hash['_content_type']
          @content      = file_or_hash[:content]       || file_or_hash['content']
          @content      = @content.unpack('m').to_s
      end
    end

    def filename
      @filename ||= File.basename(@file.path)
    end

    def content_type
      @content_type ||= (MIME::Types.type_for(@file.path).first.content_type rescue nil)
    end

    def content
      @content ||= begin
        @file.rewind if @file.eof?
        @file.read
      end
    end

    def to_hash
      {
        :_name         => filename,
        :_content_type => content_type,
        :content       => encode
      }
    end

    def to_json
      to_hash.to_json
    end

    # Encode the file contents as a Base64 (MIME_NO_LINEFEEDS) string
    #
    def encode
      [content].pack('m').tr("\n", '')
    end

    def decode
      content.unpack('m').to_s
    end

    def inspect
      %Q|<Attachment filename=#{filename}, content_type=#{content_type}, content=#{content.to_s[0..50]}...>|
    end

  end
end
