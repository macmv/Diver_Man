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

	def initialize
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
		@grid = YAML::load(File.read("data/boards.yaml"))
		@grid[10][10] = Wall.new 10, 10
		#File.open("data/boards.yaml", "w") { |f| f.write @grid.to_yaml }
		@images = {:water => Gosu::Image.new("images/water.png"),
				   :wall  => Gosu::Image.new("images/wall.png"),
				   :coin  => Gosu::Image.new("images/coin.png"),
				   :spike => Gosu::Image.new("images/spike.png")}
	end

	def draw
		@grid.each do |row|
			row.each do |item|
				item.draw @images[item.type]				
			end
		end
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
		@y -= 0.125
		@y += 0.125 if @y < 0
	end

	def move_down
		@y += 0.125
		@y -= 0.125 if @y + 1 > HEIGHT / BLOCKSIZE
	end

	def move_right
		@x += 0.125
		@x -= 0.125 if @x + 1 > WIDTH / BLOCKSIZE
	end

	def move_left
		@x -= 0.125
		@x += 0.125 if @x < 0
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

	def initialize(x, y, direction)
		super x, y
		@direction = direction
	end

	def draw(image)
		image.draw_rot(@x * BLOCKSIZE + BLOCKSIZE / 2, @y * BLOCKSIZE + BLOCKSIZE / 2, 0, @direction * 90)
	end

	def type
		:spike
	end

end

public

class Screen < Gosu::Window

	def initialize
		super WIDTH, HEIGHT, false
		self.caption = "Diver Man"
		@board = Board.new
		@diver = Diver.new
		@score = 0
		@font = Gosu::Font.new 20
	end

	def draw
		@board.draw
		@diver.draw
		@font.draw("Score: #{@score}", 5, 5, 0, 1, 1, 0xff_ffcc00)
	end

	def update
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
			initialize
		end
		if @score >= 3
			initialize
		end
		if Gosu::button_down? Gosu::KbR
			initialize
		end
	end

end

end

DiverMan::Screen.new.show