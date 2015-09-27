#! /usr/local/bin/ruby

require "gosu"
require "yaml"

def is_dot_o?(num)
	num.to_i.to_f == num
end

module DiverMan

WIDTH = 800
HEIGHT = 600
BLOCKSIZE = 40

private

class Point

	attr :x, :y

	def initialize(x, y)
		@x = x
		@y = y
	end
end
	
class Board

	def initialize(images, level)
		@grid = []
		(HEIGHT / BLOCKSIZE).times do |y|
			new_row = []
			(WIDTH / BLOCKSIZE).times do |x|
				new_row.push Water.new(x, y)
			end
			@grid.push new_row
		end
		30.times do
			new_x = rand(WIDTH / BLOCKSIZE)
			new_y = rand(HEIGHT / BLOCKSIZE)
			@grid[new_y][new_x] = Wall.new new_x, new_y
		end
		5.times do
			new_x = rand(WIDTH / BLOCKSIZE)
			new_y = rand(HEIGHT / BLOCKSIZE)
			@grid[new_y][new_x] = Spike.new new_x, new_y, rand(4)
		end
		3.times do
			new_x = rand(WIDTH / BLOCKSIZE)
			new_y = rand(HEIGHT / BLOCKSIZE)
			@grid[new_y][new_x] = Coin.new new_x, new_y
		end
		@grid = YAML::load(File.read("data/boards.yaml"))[level]
		#File.open("data/boards.yaml", "w") { |f| f.write (Array.new + [@grid]).to_yaml }
		@images = images
		@new_grid = nil
	end

	def draw
		if @new_grid != nil
			@new_grid.each do |row|
				row.each do |item|
					item.draw @images[item.type]				
				end
			end
			return nil
		else
			if @grid == nil
				return true
			end
			@grid.each do |row|
				row.each do |item|
					item.draw @images[item.type]				
				end
			end
		end
		false
	end

	def got_coin(diver)
		top_left = Point.new(diver.x.to_i, diver.y.to_i)
		top_right = nil
		bottom_left = nil
		bottom_right = nil
		if is_dot_o?(diver.x) == false
			top_right = Point.new(diver.x.to_i + 1, diver.y.to_i)
			x_not_is_dot_o = true
		end
		if is_dot_o?(diver.y) == false
			bottom_left = Point.new(diver.x.to_i, diver.y.to_i + 1)
			if x_not_is_dot_o
				bottom_right = Point.new(diver.x.to_i + 1, diver.y.to_i + 1)
			end
		end
		return_arr = []
		return_arr[0] = @grid[top_left.y    ][top_left.x    ].type
		return_arr[1] = @grid[top_right.y   ][top_right.x   ].type if top_right    != nil
		return_arr[2] = @grid[bottom_left.y ][bottom_left.x ].type if bottom_left  != nil
		return_arr[3] = @grid[bottom_right.y][bottom_right.x].type if bottom_right != nil
		return_score = 0
		if return_arr.include? :coin
			return_arr.each_with_index do |item, index|
				if item == :coin
					if index == 0
						@grid[top_left.y][top_left.x]         = Water.new(top_left.x, top_left.y)
					elsif index == 1
						@grid[top_right.y][top_right.x]       = Water.new(top_right.x, top_right.y)
					elsif index == 2
						@grid[bottom_left.y][bottom_left.x]   = Water.new(bottom_left.x, bottom_left.y)
					else		
						@grid[bottom_right.y][bottom_right.x] = Water.new(bottom_right.x, bottom_right.y)
					end
					return_score += 1
				end
			end
		end
		return_score
	end

	def new_level
		@new_grid = []
		(HEIGHT / BLOCKSIZE).times do |y|
			new_row = []
			(WIDTH / BLOCKSIZE).times do |x|
				new_row.push Water.new(x, y)
			end
			@new_grid.push new_row
		end
	end

	def click(x, y)
		if @new_grid[y][x].type == :water
			puts :new_wall
			@new_grid[y][x] = Wall.new x, y
		elsif @new_grid[y][x].type == :wall
			puts :new_coin
			@new_grid[y][x] = Coin.new x, y
		elsif @new_grid[y][x].type == :coin
			puts :new_spike
			@new_grid[y][x] = Spike.new x, y, 0
		elsif @new_grid[y][x].type == :spike
			puts :rotate_spike
			@new_grid[y][x].turn
		end
		if @new_grid[y][x].type == :spike && @new_grid[y][x].direction > 3
			puts :new_water
			@new_grid[y][x] = Water.new x, y
		end
	end

	def save_level
		@grid = @new_grid
		all_levels = YAML::load(File.read("data/boards.yaml"))
		all_levels.push @grid
		File.open("data/boards.yaml", "w") { |f| f.write all_levels.to_yaml }
		@new_grid = nil
	end

	def [](num)
		@grid[num]
	end

end

class Diver

	attr_reader :x, :y

	def initialize
		@x = (WIDTH / BLOCKSIZE / 2).to_f
		@y = (HEIGHT / BLOCKSIZE / 2).to_f
		@image = Gosu::Image.new "images/diver.png"
	end

	def draw
		@image.draw(@x * BLOCKSIZE, @y * BLOCKSIZE, 0)
	end

	def block_tuching(board)
		top_left = Point.new(@x.to_i, @y.to_i)
		top_right = nil
		bottom_left = nil
		bottom_right = nil
		if is_dot_o?(@x) == false
			top_right = Point.new(@x.to_i + 1, @y.to_i)
			x_not_is_dot_o = true
		end
		if is_dot_o?(@y) == false
			bottom_left = Point.new(@x.to_i, @y.to_i + 1)
			if x_not_is_dot_o
				bottom_right = Point.new(@x.to_i + 1, @y.to_i + 1)
			end
		end
		return_arr = []
		return_arr[0] = board[top_left.y    ][top_left.x    ].type
		return_arr[1] = board[top_right.y   ][top_right.x   ].type if top_right    != nil
		return_arr[2] = board[bottom_left.y ][bottom_left.x ].type if bottom_left  != nil
		return_arr[3] = board[bottom_right.y][bottom_right.x].type if bottom_right != nil
		return_arr
	end

	def move_up
		@y -= 0.0625
		@y += 0.0625 if @y < 0
	end

	def move_down
		@y += 0.0625
		@y -= 0.0625 if @y + 1 > HEIGHT / BLOCKSIZE
	end

	def move_right
		@x += 0.0625
		@x -= 0.0625 if @x + 1 > WIDTH / BLOCKSIZE
	end

	def move_left
		@x -= 0.0625
		@x += 0.0625 if @x < 0
	end

end

class Block

	def initialize(x, y)
		@x = x
		@y = y
	end

	def draw(image)
		image.draw(@x * BLOCKSIZE, @y * BLOCKSIZE, 0)
	end

	def ==(other)
		other.class == self.class
	end

	def eql?(other)
		self == other
	end

	def hash
		[].hash
	end

end

class Water < Block

	def initialize(x, y)
		super x, y
	end

	def type
		:water
	end

end

class Wall < Block

	def initialize(x, y)
		super x, y
	end

	def type
		:wall
	end

end

class Coin < Block

	def initialize(x, y)
		super x, y
	end

	def type
		:coin
	end

end

class Spike < Block

	attr_reader :direction

	def initialize(x, y, direction)
		super x, y
		@direction = direction
	end

	def draw(image)
		image.draw_rot(@x * BLOCKSIZE + BLOCKSIZE / 2, @y * BLOCKSIZE + BLOCKSIZE / 2, 0, @direction * 90)
	end

	def turn
		@direction += 1
	end

	def type
		:spike
	end

end

public

class Screen < Gosu::Window

	def initialize(level)
		super WIDTH, HEIGHT, false
		self.caption = "Diver Man"
		@images = {:water => Gosu::Image.new("images/water.png"),
					:wall  => Gosu::Image.new("images/wall.png"),
					:coin  => Gosu::Image.new("images/coin.png"),
					:spike => Gosu::Image.new("images/spike.png")}
		@board       = Board.new @images, level
		@diver       = Diver.new
		@score       = 0
		@font        = Gosu::Font.new 20
		@big_font    = Gosu::Font.new 140
		@level       = level
		@game_end    = false
		@statice     = :home
		@home_screen = Gosu::Image.new "images/home screen.png"
		@ms_down     = false
	end

	def draw
		if @statice == :home
			@home_screen.draw(0, 0, 0)
		elsif @statice == :in_game
			failed_draw = @board.draw
			if failed_draw
				@big_font.draw_rel("YOU WON!!!!", WIDTH / 2, HEIGHT / 2, 0, 0.5, 0.5, 1, 1, 0xff_00ffff)
				@game_end = true
			else
				@diver.draw
				@font.draw("Score: #{@score}", 5, 5, 0, 1, 1, 0xff_ffcc00)
				@font.draw("Level: #{@level + 1}", 5, 25, 0, 1, 1, 0xff_ffcc00)
			end
		elsif @statice == :level_editor
			@board.draw
			@diver.draw
			@font.draw("Score: #{@score}", 5, 5, 0, 1, 1, 0xff_ffcc00)
			@font.draw("Level: #{@level + 1}", 5, 25, 0, 1, 1, 0xff_ffcc00)
		end
	end

	def update
		if @game_end
			sleep 2
			exit
		end
		if Gosu::button_down?(Gosu::KbH) && Gosu::button_down?(Gosu::KbLeftControl)
			@statice = :home
		end
		if Gosu::button_down?(Gosu::KbL) && Gosu::button_down?(Gosu::KbLeftControl)
			@statice = :level_editor
			@board.new_level
		end
		if Gosu::button_down?(Gosu::KbS) && Gosu::button_down?(Gosu::KbLeftControl)
			@statice = :in_game
		end
		if @statice == :home
		elsif @statice == :in_game
			if Gosu::button_down? Gosu::KbW
				@diver.move_up
				tuching_arr = @diver.block_tuching(@board)
				if tuching_arr.include? :wall
					@diver.move_down
				end
			end
			if Gosu::button_down? Gosu::KbA
				@diver.move_left
				tuching_arr = @diver.block_tuching(@board)
				if tuching_arr.include? :wall
					@diver.move_right
				end
			end
			if Gosu::button_down? Gosu::KbS
				@diver.move_down
				tuching_arr = @diver.block_tuching(@board)
				if tuching_arr.include? :wall
					@diver.move_up
				end
			end
			if Gosu::button_down? Gosu::KbD
				@diver.move_right
				tuching_arr = @diver.block_tuching(@board)
				if tuching_arr.include? :wall
					@diver.move_left
				end
			end
			tuching_arr = @diver.block_tuching(@board)
			if tuching_arr.include? :coin
				@score += @board.got_coin(@diver)
			end
			if tuching_arr.include? :spike
				initialize @level
			end
			if @score >= 3
				initialize @level + 1
			end
			if Gosu::button_down? Gosu::KbR
				initialize @level
			end
		elsif @statice == :level_editor
			if Gosu::button_down?(Gosu::KbReturn) && Gosu::button_down?(Gosu::KbLeftControl)
				@board.save_level
				@statice = :home
			end
			if Gosu::button_down?(Gosu::MsLeft) && @ms_down == false
				puts "click"
				click_x = (mouse_x / BLOCKSIZE).to_i
				click_y = (mouse_y / BLOCKSIZE).to_i
				@board.click(click_x, click_y)
				@ms_down = true
			end
		end
	end

	def button_up(id)
		if id == Gosu::MsLeft
			@ms_down = false
		end
	end

	def needs_cursor?
		true
	end

end

end

DiverMan::Screen.new(0).show