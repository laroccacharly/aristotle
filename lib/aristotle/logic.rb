module Aristotle
  class Logic
    attr_reader :break_keyword
    attr_accessor :chain_rules, :break_chain
    def initialize(object, break_keyword = "STOP", commands = [])
      @object = object
      @chain = :break_on_first
      @break_chain = false
      @break_keyword = break_keyword
      self.class.load_commands(commands)
    end

    def chain_rules?
      @chain_rules == :chain_rules
    end

    def process(logic_method)
      results = []
      self.class.commands(logic_method).each do |command|
        next unless command.condition_passes_with?(@object)

        results << command.do_action_with(@object, self)
        break unless (chain_rules? && !@break_chain)
      end
      @break_chain = false
      return nil if results.empty?
      return results.length == 1 ? results.first : results
    end

    def self.commands(logic_method = nil)
      logic_method.nil? ? @commands : (@commands[logic_method] || [])
    end

    # called when class is loaded
    def self.condition(expression, &block)
      @conditions ||= {}
      @conditions[expression] = block
    end

    # called when class is loaded
    def self.action(expression, &block)
      @actions ||= {}
      @actions[expression] = block
    end

    def self.load_commands(commands = [])
      # If argument 'commands' present load from it else load from file
      if commands.any?
        @commands = []
        commands.each do |command|
          @commands << Aristotle::Command.new(command, @conditions || {}, @actions || {})
        end
      else
        load_commands_from_file
      end
    end

    def self.load_commands_from_file
      @commands ||= {}

      return if @commands != {}

      filename = "app/logic/#{logic_name}.logic"
      logic_data = File.read(filename)

      command = nil

      lines = logic_data.split("\n").map(&:rstrip).select { |l| l != '' && !l.strip.start_with?('#') }
      lines.each do |line|
        if line.start_with? '  '
          raise "#{filename} is broken!" if command.nil?

          @commands[command] ||= []
          @commands[command] << Aristotle::Command.new(line.strip, @conditions || {}, @actions || {})
        else
          command = line
        end
      end
    end

    def self.html_rules
      Aristotle::Presenter.new(self).html_rules
    end

    def self.logic_name
      self.to_s.gsub(/Logic$/, '').gsub(/([a-z])([A-Z])/, '\1_\2').downcase
    end
  end
end
