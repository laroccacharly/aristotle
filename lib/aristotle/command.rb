module Aristotle
  class Command
    attr_reader :action, :condition, :action_proc, :condition_proc

    def initialize(line, conditions, actions)
      @action, @condition = line.split(' if ', 2).map(&:strip)

      raise 'Badly formatted line' if @action == '' || @condition == ''

      @action_tokens = @action.split(' and ').map(&:strip)
      @condition_tokens = @condition.split(' and ').map(&:strip)

      @condition_procs = []
      @condition_attributes = []
      @condition_tokens.each do |condition_token|
        conditions.each do |condition_regexp, condition_proc|
          match_data = condition_regexp.match(condition_token)
          if match_data
            @condition_procs << condition_proc
            @condition_attributes << match_data.to_a[1..-1]
          end
        end
      end

      @action_procs = []
      @action_attributes = []
      @action_tokens.each do |action_token|
        actions.each do |action_regexp, action_proc|
          match_data = action_regexp.match(action_token)
          if match_data
            @action_procs << action_proc
            @action_attributes << match_data.to_a[1..-1]
          end
        end
      end
    end

    def do_action_with(object, sender)
      unless @action_procs.empty?
        results = []
        @action_procs.each_with_index do |action, index|
          results << action.call(object, *@action_attributes[index])
        end
        if results.last == sender.break_keyword
          sender.break_chain = true
          results.slice!(-1)
        end
        return results.length == 1 ? results.first : results
      else
        raise "No action defined"
      end
    end

    def condition_passes_with?(object)
      unless @condition_procs.empty?
        @condition_procs.each_with_index do |condition, index|
          result = condition.call(object, *@condition_attributes[index])
          return false if result == false
        end
      else
        raise "No condition defined"
      end
    end

    def has_action?
      !@action_procs.empty?
    end

    def has_condition?
      !@condition_procs.empty?
    end
  end
end
