module Tire
  class Attachment
    def initialize(file)
      @file = file
    end

    def filename
      File.basename(@file.path)
    end

    def content_type
      MIME::Types.type_for(@file.path).first.content_type rescue nil
    end

    def to_json
      {
        :_name         => filename,
        :_content_type => content_type,
        :content       => encode_base64
      }.to_json
    end

    private

    # Read the file contents and encode it as base64 (MIME_NO_LINEFEEDS)
    #
    def encode_base64
      @file.rewind if @file.eof?
      [@file.read].pack('m').tr("\n", '')
    end

  end
end
