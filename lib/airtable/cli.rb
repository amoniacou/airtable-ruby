require 'optparse'
require 'airtable'

module Airtable
  # Command line Class
  class CLI
    def initialize(args)
      trap_interrupt
      @args    = args
      @options = {}
      @parser  = OptionParser.new
    end

    def start
      add_banner
      add_options
      add_tail_options
      add_supported_operations
      @parser.parse!(@args)
      if @options.empty?
        puts @parser
      else
        unless valid_options?
          puts @parser
          return
        end
        run_operation
      end
    end

    def add_banner
      @parser.banner = 'Usage: airtable [options]'
      @parser.separator ''
    end

    def add_options
      @parser.separator 'Common options:'
      @parser.on('-kKEY', '--api_key=KEY', 'Airtable API key') do |key|
        @options[:api_key] = key
      end
      @parser.on('-tNAME', '--table NAME', 'Table Name') do |table|
        @options[:table_name] = table
      end
      @parser.on('-bBASE_ID', '--base BASE_ID', 'Base ID') do |base_id|
        @options[:base_id] = base_id
      end
      @parser.on('-rRECORD_ID', '--record RECORD_ID', 'Record ID') do |record_id|
        @options[:record_id] = record_id
      end
      @parser.on('-fFIELD_NAME', '--field FIELD_NAME', 'Field name to update or read') do |field_name|
        @options[:field_name] = field_name
      end
      @parser.on('-vVALUE', '--value VALUE', 'Field value for update') do |field_value|
        @options[:field_value] = field_value
      end
    end

    def add_tail_options
      @parser.on_tail('-h', '--help', 'Show this message') do
        puts @parser
        exit
      end
      @parser.on_tail('--version', 'Show version') do
        puts ::Airtable::VERSION
        exit
      end
    end

    def add_supported_operations
      @parser.separator ''
      @parser.separator 'Supported Operations:'
      @parser.separator "\tGet Record (if only RECORD_ID provided)"
      @parser.separator "\tGet Field (if RECORD_ID and FIELD_ID are provided)"
      @parser.separator "\tUpdate Field (if RECORD_ID, FIELD_ID and VALUE are provided)"
      @parser.separator ''
    end

    def valid_options?
      @options[:table_name] && !@options[:table_name].empty? &&
        @options[:base_id] && !@options[:base_id].empty? &&
        @options[:record_id] && !@options[:record_id].empty?
    end

    def run_operation
      if @options[:field_value] && !@options[:field_value].empty? && @options[:field_name] && !@options[:field_name].empty?
        update_field
      elsif @options[:field_name] && !@options[:field_name].empty?
        print_field
      else
        print_record
      end
    end

    def print_record
      record = ::Airtable::Client.new(@options[:api_key]).base(@options[:base_id]).table(@options[:table_name]).find(@options[:record_id])
      puts ({ id: record.id, fields: record.fields, createdTime: record.created_at }).to_json
    end

    def print_field
      record = ::Airtable::Client.new(@options[:api_key]).base(@options[:base_id]).table(@options[:table_name]).find(@options[:record_id])
      puts record.fields[@options[:field_name]]
    end

    def update_field
      ::Airtable::Client.new(@options[:api_key]).base(@options[:base_id]).table(@options[:table_name])
                        .update(@options[:record_id], @options[:field_name] => @options[:field_value])
      record = ::Airtable::Client.new(@options[:api_key]).base(@options[:base_id]).table(@options[:table_name]).find(@options[:record_id])
      if record.fields[@options[:field_name]] == @options[:field_value]
        puts 'OK'
      else
        puts 'ERROR'
      end
    end

    def trap_interrupt
      trap('INT') { exit!(1) }
    end
  end
end
