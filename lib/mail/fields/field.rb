module Mail
  # Provides a single class to call to create a new structured or unstructured
  # field.  Works out per RFC what type of field it is being given and returns
  # the correct type of class back on new.
  # 
  # ===Per RFC 2822
  #  
  #  2.2. Header Fields
  #  
  #     Header fields are lines composed of a field name, followed by a colon
  #     (":"), followed by a field body, and terminated by CRLF.  A field
  #     name MUST be composed of printable US-ASCII characters (i.e.,
  #     characters that have values between 33 and 126, inclusive), except
  #     colon.  A field body may be composed of any US-ASCII characters,
  #     except for CR and LF.  However, a field body may contain CRLF when
  #     used in header "folding" and  "unfolding" as described in section
  #     2.2.3.  All field bodies MUST conform to the syntax described in
  #     sections 3 and 4 of this standard.
  #  
  class Field
    
    require File.join(File.dirname(__FILE__), '..', 'patterns')
    include Patterns
    
    # Generic Field Exception
    class FieldError < StandardError
    end

    # Raised when a parsing error has occurred (ie, a StructuredField has tried
    # to parse a field that is invalid or improperly written)
    class ParseError < FieldError #:nodoc:
    end

    # Raised when attempting to set a structured field's contents to an invalid syntax
    class SyntaxError < FieldError #:nodoc:
    end
    
    require File.join(File.dirname(__FILE__), 'structured_field')
    require File.join(File.dirname(__FILE__), 'unstructured_field')

    # Load in all header field types
    TypeFiles = Dir.glob(File.join(File.dirname(__FILE__), "types/*.rb"))
    
    TypeFiles.each do |field|
      require field
    end
    
    # Accepts a text string in the format of:
    # 
    #  "field-name: field data"
    # 
    # Note, does not want a terminating carriage return.  Returns
    # self appropriately parsed
    def initialize(raw_field_text)
      name, value = split(raw_field_text)
      create_field(name, value)
      return self
    end

    def field=(value)
      @field = value
    end
    
    def field
      @field
    end
    
    def name
      field.name
    end
    
    def name=(value)
      field.name = value
    end
    
    def value
      field.value
    end
    
    def value=(value)
      field.value = value
    end
    
    def to_s
      field.to_s
    end
    
    private
    
    def split(raw_field)
      match_data = raw_field.match(/^(#{FIELD_NAME}):\s(#{FIELD_BODY})$/)
      [match_data[1], match_data[2]]
    rescue
      STDERR.puts "WARNING: Could not parse (and so ignorning) '#{raw_field}'"
    end
    
    STRUCTURED_FIELDS = %w[ date from sender reply-to to cc bcc message-id in-reply-to
                            references keywords resent-date resent-from resent-sender
                            resent-to resent-cc resent-bcc resent-message-id 
                            return-path received ]

    def create_field(name, value)
      begin
        self.field = new_field(name, value)
      rescue
        self.field = Mail::UnstructuredField.new(name, value)
      end
    end

    def new_field(name, value)
      # Could do this with constantize et al, but a simple case is less krufty
      case name.downcase
      when /^to$/
        ToField.new(name,value)
      when /^cc$/
        CcField.new(name,value)
      when /^bcc$/
        BccField.new(name, value)
      when /^message-id$/
        MessageIdField.new(name, value)
      when /^in-reply-to$/
        InReplyToField.new(name, value)
      when /^references$/
        ReferencesField.new(name, value)
      when /^subject$/
        SubjectField.new(name, value)
      when /^comments$/
        CommentsField.new(name, value)
      when /^keywords$/
        KeywordsField.new(name, value)
      when /^date$/
        DateField.new(name, value)
      when /^from$/
        FromField.new(name, value)
      when /^sender$/
        SenderField.new(name, value)
      when /^reply-to$/
        ReplyToField.new(name, value)
      when /^resent-date$/
        ResentDateField.new(name, value)
      when /^resent-from$/
        ResentFromField.new(name, value)
      when /^resent-sender$/ 
        ResentSenderField.new(name, value)
      when /^resent-to$/
        ResentToField.new(name, value)
      when /^resent-cc$/
        ResentCcField.new(name, value)
      when /^resent-bcc$/
        ResentBccField.new(name, value)
      when /^resent-msg-id$/
        ResentMsgIdField.new(name, value)
      when /^return-path$/
        ReturnPathField.new(name, value)
      when /^received$/
        ReceivedField.new(name, value)
      else 
        OptionalField.new(name, value)
      end
      
    end

  end
  
end
