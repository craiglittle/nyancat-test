require 'minitest/unit'

class NyanCat

  ESC      = "\e["
  NND      = "#{ESC}0m"
  PASS     = '='
  PASS_ARY = ['-', '_']
  FAIL     = '*'
  ERROR    = '!'
  PENDING  = '+'



  attr_reader :current, :example_results, :color_index, :pending_count,
              :failure_count, :example_count

  # Increments the example count and displays the current progress
  #
  # @returns nothing
  def tick(mark = PASS)
    @example_results << mark
    @current = (@current > @example_count) ? @example_count : @current + 1
    dump_progress
  end

  # Determine which Ascii Nyan Cat to display. If tests are complete,
  # Nyan Cat goes to sleep. If there are failing or pending examples,
  # Nyan Cat is concerned.
  #
  # @return [String] Nyan Cat
  def nyan_cat
    if self.failed_or_pending? && self.finished?
      ascii_cat('x')[@color_index%2].join("\n") #'~|_(x.x)'
    elsif self.failed_or_pending?
      ascii_cat('o')[@color_index%2].join("\n") #'~|_(o.o)'
    elsif self.finished?
      ascii_cat('-')[@color_index%2].join("\n") # '~|_(-.-)'
    else
      ascii_cat('^')[@color_index%2].join("\n") # '~|_(^.^)'
    end
  end

  # Displays the current progress in all Nyan Cat glory
  #
  # @return nothing
  def dump_progress
    padding = @example_count.to_s.length * 2 + 2
    line = nyan_trail.split("\n").each_with_index.inject([]) do |result, (trail, index)|
      value = "#{scoreboard[index]}/#{@example_count}:"
      result << format("%s %s", value, trail)
    end.join("\n")
    output.print line + eol
  end

  # Determines how we end the trail line. If complete, return a newline etc.
  #
  # @return [String]
  def eol
    return "\n" if @current == @example_count
    length = (nyan_cat.split("\n").length - 1)
    length > 0 ? format("\e[1A" * length + "\r") : "\r"
  end

  # Calculates the current flight length
  #
  # @return [Fixnum]
  def current_width
    padding    = @example_count.to_s.length * 2 + 6
    cat_length = nyan_cat.split("\n").group_by(&:size).max.first
    padding    + @current + cat_length
  end

  # A Unix trick using stty to get the console columns
  #
  # @return [Fixnum]
  def terminal_width
    if defined? JRUBY_VERSION
      default_width = 80
    else
      default_width = `stty size`.split.map { |x| x.to_i }.reverse.first - 1
    end
    @terminal_width ||= default_width
  end

  # Creates a data store of pass, failed, and pending example results
  # We have to pad the results here because sprintf can't properly pad color
  #
  # @return [Array]
  def scoreboard
    @pending_examples ||= []
    @failed_examples ||= []
    padding = @example_count.to_s.length
    [ @current.to_s.rjust(padding),
      green((@current - @pending_examples.size - @failed_examples.size).to_s.rjust(padding)),
      yellow(@pending_examples.size.to_s.rjust(padding)),
      red(@failed_examples.size.to_s.rjust(padding)) ]
  end

  # Creates a rainbow trail
  #
  # @return [String] the sprintf format of the Nyan cat
  def nyan_trail
    marks = @example_results.map{ |mark| highlight(mark) }
    marks.shift(current_width - terminal_width) if current_width >= terminal_width
    nyan_cat_lines = nyan_cat.split("\n").each_with_index.map do |line, index|
      format("%s#{line}", marks.join)
    end.join("\n")
  end

  # Ascii version of Nyan cat. Two cats in the array allow Nyan to animate running.
  #
  # @param o [String] Nyan's eye
  # @return [Array] Nyan cats
  def ascii_cat(o = '^')
    [[ "_,------,   ",
        "_|  /\\_/\\ ",
        "~|_( #{o} .#{o})  ",
        " \"\"  \"\" "
      ],
      [ "_,------,   ",
        "_|   /\\_/\\",
        "^|__( #{o} .#{o}) ",
        "  \"\"  \"\"    "
      ]]
  end

  # Colorizes the string with raindow colors of the rainbow
  #
  # @params string [String]
  # @return [String]
  def rainbowify(string)
    c = colors[@color_index % colors.size]
    @color_index += 1
    "#{ESC}38;5;#{c}m#{string}#{NND}"
  end

  # Calculates the colors of the rainbow
  #
  # @return [Array]
  def colors
    @colors ||= (0...(6 * 7)).map do |n|
      pi_3 = Math::PI / 3
      n *= 1.0 / 6
      r  = (3 * Math.sin(n           ) + 3).to_i
      g  = (3 * Math.sin(n + 2 * pi_3) + 3).to_i
      b  = (3 * Math.sin(n + 4 * pi_3) + 3).to_i
      36 * r + 6 * g + b + 16
    end
  end

  # Determines how to color the example.  If pass, it is rainbowified, otherwise
  # we assign red if failed or yellow if an error occurred.
  #
  # @return [String]
  def highlight(mark = PASS)
    case mark
    when PASS; rainbowify PASS_ARY[@color_index%2]
    when FAIL; "\e[31m#{mark}\e[0m"
    when ERROR; "\e[33m#{mark}\e[0m"
    when PENDING; "\e[33m#{mark}\e[0m"
    else mark
    end
  end

  # Converts a float of seconds into a minutes/seconds string
  #
  # @return [String]
  def format_duration(duration)
    seconds = ((duration % 60) * 100.0).round / 100.0   # 1.8.7 safe .round(2)
    seconds = seconds.to_i if seconds.to_i == seconds   # drop that zero if it's not needed

    message = "#{seconds} second#{seconds == 1 ? "" : "s"}"
    message = "#{(duration / 60).to_i} minute#{(duration / 60).to_i == 1 ? "" : "s"} and " + message if duration >= 60

    message
  end


  # Determines if the specs have completed
  #
  # @returns [Boolean] true if finished; false otherwise
  def finished?
    (@current == @example_count)
  end

  # Determines if the any specs failed or are in pending state
  #
  # @returns [Boolean] true if failed or pending; false otherwise
  def failed_or_pending?
    (@failure_count.to_i > 0 || @pending_count.to_i > 0)
  end

  def color(text, color_code)
    color_enabled? ? "#{color_code}#{text}\e[0m" : text
  end

  def color_enabled?
    true
  end

  def bold(text)
    color(text, "\e[1m")
  end

  def red(text)
    color(text, "\e[31m")
  end

  def green(text)
    color(text, "\e[32m")
  end

  def yellow(text)
    color(text, "\e[33m")
  end

  def blue(text)
    color(text, "\e[34m")
  end

  def magenta(text)
    color(text, "\e[35m")
  end

  def cyan(text)
    color(text, "\e[36m")
  end

  def white(text)
    color(text, "\e[37m")
  end

  def short_padding
    '  '
  end

  def long_padding
    '     '
  end


  # The IO we're going to pipe through.
  attr_reader :io

  def initialize io # :nodoc:
    #::MiniTest::Unit::TestCase.i_suck_and_my_tests_are_order_dependent!

    @io = io
    # stolen from /System/Library/Perl/5.10.0/Term/ANSIColor.pm
    # also reference http://en.wikipedia.org/wiki/ANSI_escape_code
    @example_results = []
    @failed_examples = []
    @pending_examples = []
    @current = 0
    @example_count = 100
    @color_index = 0
    # io.sync = true
  end
  alias_method :output, :io

  ##
  # Wrap print to colorize the output.

  def print o
    case o
    when "."
      tick(PASS)
    when "E"
      @failed_examples << ERROR
      tick(ERROR)
    when "F"
      @failed_examples << ERROR
      tick(FAIL)
    when "S"
      @pending_examples << PENDING
      tick(PENDING)
    end
  end

  def puts(*o) # :nodoc:
    super
  end

  def method_missing msg, *args # :nodoc:
    io.send(msg, *args)
  end

end

class MiniTest::Unit
  def _run_anything type
    nyan_cat = NyanCat.new(Object.new)

    suites = TestCase.send "#{type}_suites"
    return if suites.empty?

    start = Time.now

    start_message = "# Nyaning #{type}s:".split(//).map { |c| nyan_cat.send(:rainbowify, c) }.join
    puts
    puts start_message
    puts

    @test_count, @assertion_count = 0, 0
    sync = output.respond_to? :"sync=" # stupid emacs
    old_sync, output.sync = output.sync, true if sync

    results = _run_suites suites, type

    @test_count      = results.inject(0) { |sum, (tc, _)| sum + tc }
    @assertion_count = results.inject(0) { |sum, (_, ac)| sum + ac }

    output.sync = old_sync if sync

    t = Time.now - start

    final_message = "Nyan Cat rocked your world for %.6fs, %.4f tests/s, %.4f assertions/s." % \
      [t, test_count / t, assertion_count / t]
    final_message = final_message.split(//).map { |c| nyan_cat.send(:rainbowify, c) }.join

    puts
    puts
    puts final_message

    report.each_with_index do |msg, i|
      puts "\n%3d) %s #{nyan_cat.send(:cyan, '=^..^=')}" % [i + 1, msg]
    end

    puts

    status
  end
end

MiniTest::Unit.output = NyanCat.new(MiniTest::Unit.output)
