
class Hangman
  attr_reader :guesser, :referee, :board
  
  def initialize(players)
    @guesser = players[:guesser]
    @referee = players[:referee]
    @board = nil
    @turns = 10
  end
  
  def setup
    length = @referee.pick_secret_word
    @guesser.register_secret_length(length)
    @board = Array.new(length, "_")
  end
  
  def take_turn
    guess = @guesser.guess(@board)
    positions = @referee.check_guess(guess, @board)
    @turns -= 1 if positions.empty?
    update_board(guess, positions)
    @guesser.handle_response(guess, positions)
  end
  
  def update_board(guess, positions)
    positions.each {|i| @board[i]=guess}
  end
  
  def display
    system("clear")
    print "#{board.join(" ")}\n"
  end
  
  def winner
    if !board.include?("_")
      return guesser
    end
    referee
  end
  
  def declare_winner
    if winner.is_a? HumanPlayer
      puts "Congratulations, you won in #{10-@turns} turns!"
    else
      puts "Game over. Computer won in #{10-@turns} turns"
    end
  end
  
  def declare_secret_word
    if referee.is_a? ComputerPlayer
      puts "The secret word was #{referee.secret_word}"
    elsif @board.include?("_")
      puts "What was the secret_word?"
      answer = gets.chomp
      puts "The secret word was #{answer}"
    else
      puts "The secret word was #{@board.join("")}"
    end
  end
  
  def play
    setup
    until over?
      display
      puts "Remaining turns : #{@turns}"
      take_turn
    end
    declare_winner
    declare_secret_word
  end
  
  def over?
    if !board.include?("_") or @turns==0
      return true
    end
    false
  end
    
end

class HumanPlayer
  def initialize
    @secret_word = nil
    @secret_word_length = 0
    @guessed_letters = []
  end
  
  def pick_secret_word
    puts "Pick a secret word:"
    begin
      puts "Enter the number of letters your secret word contains:"
      answer = gets.chomp
      word_length = answer.to_i
    rescue
      puts "Error in entering the integer"
    retry
    end
    word_length
  end
  
  def register_secret_length(length)
    @secret_word_length =length
  end
  
  def guess(board)
    begin
      puts "Guess a letter"
      answer = gets.chomp
      if answer.length != 1 || !(answer =~ /[A-Za-z]/) || @guessed_letters.include?(answer)
        raise("Enter a letter")
      end
    rescue
      puts "Error in getting letter"
    retry
    end
    result = answer.downcase
    @guessed_letters.push(result)
    result
  end
  
  def check_guess(guess, board=[])
    begin
      puts "Give the positions of the occurances of '#{guess}' (i.e. 1,2. Hit enter if none)"
      answer = gets.chomp
      positions = answer.split(",").map {|i| Integer(i)}
      is_valid_pos(positions, board)
    rescue
      puts "Error in getting positions."
      retry
    end
    positions
  end
  
  def is_valid_pos(positions, board)
    positions.each do |i|
      if i>board.length-1 || i<0
        raise("Out of range")
      elsif board[i]!="_"
        raise("This spot is taken")
      end
    end
  end
  
  def handle_response(guess, positions)
  end
end

class ComputerPlayer
  def self.file_to_dictionary(file)
    ComputerPlayer.new(File.readlines(file).map(&:chomp))
  end
  
  attr_reader :candidate_words, :secret_word
  
  def initialize(dictionary)
    @dictionary = dictionary
    @secret_word = nil
    @secret_word_length = nil
    @prev_guesses = []
  end  
  
  def pick_secret_word
    @secret_word = @dictionary.sample
    @secret_word.length
  end
  
  def check_guess(guess, board=[])
    positions = []
    @secret_word.split("").each_with_index do |letter, i|
      if guess == letter
        positions.push(i)
      end
    end
    positions
  end
  
  def register_secret_length(length)
    @secret_word_length = length
    @candidate_words = @dictionary.select {|item| item.length==@secret_word_length}
  end
  
  def guess(board)
    letter = most_common_letter(@candidate_words, @prev_guesses+board)
    @prev_guesses.push(letter)
    letter
  end
  
  def handle_response(guess, positions)
    # words that contain the letter guess in the specific position
    positions.each do |i|
    @candidate_words.select! {|word| word[i]==guess}
    end
    (0...(@secret_word_length)).each do |i|
      unless positions.include?(i)
        @candidate_words.reject! {|word| word[i]==guess}
      end
    end
  end
  
  def most_common_letter(words, ignored_letters)
    letters_occurance = Hash.new(0)
    words.each do |word|
      letters_array = []
      word.each_char do |letter|
        unless ignored_letters.include?(letter) || letters_array.include?(letter)
          letters_occurance[letter] += 1
          letters_array.push(letter)
        end
      end
    end
    highest = 0
    result = nil
    letters_occurance.each do |key, value|
      if value>highest
        highest = value
        result = key
      end
    end
    result
  end
      
end

if __FILE__ == $PROGRAM_NAME
  puts "Guesser : Computer? y/n"
  answer = gets.chomp
  if answer=="y"
    guesser = ComputerPlayer.file_to_dictionary("dictionary.txt")
  else
    guesser = HumanPlayer.new
  end
  
  puts "Referee : Computer? y/n"
  answer = gets.chomp
  if answer=="y"
    referee = ComputerPlayer.file_to_dictionary("dictionary.txt")
  else
    referee = HumanPlayer.new
  end
  
  Hangman.new({guesser: guesser, referee: referee}).play
end