require_relative 'functions'
require_relative 'reportable'
require_relative './umatrix2.rb'

module SOM
  class SOM
    include Functions
    include Reportable

    attr_accessor :output_space, :input_patterns, :learning_rate, :radius, :bmus_position, :epochs, :umatrix, :initial_radius, :initial_learning_rate , :input_patterns, :max, :min

    def initialize learning_rate: 0.6,
                   output_space_size: 4,
                   epochs: 100,
                   radius_type: :circular,
                   input_patterns: nil,
                   force_radius: nil
      @epochs = epochs
      @umatrix = nil #Matrix.new( output_space_size ){ Array.new(output_space_size) }
      @umatrixbla = nil #Matrix.new( output_space_size ){ Array.new(output_space_size) }
      @learning_rate = learning_rate
      @bmus_position = {}
      @input_patterns = input_patterns
      @output_space =  if input_patterns.nil?
                         OutputSpace.new( size: output_space_size,radius_type: radius_type )
                       else
                         OutputSpace.new( size: output_space_size,radius_type: radius_type , random_fill: true, vec_size: input_patterns.first.size ) unless input_patterns.nil?
                       end
      @radius =  force_radius || (measures.max/2.0).round(0)
      @initial_radius =  @radius
      @initial_learning_rate = @learning_rate
    end

    def epoch iteration=1, &block
      input_patterns.each do |input_pattern|
        wn = output_space.find_winning_neuron(input_pattern)
        wn_position = output_space.find_neuron_position(wn)
        update_bmus_position( input_pattern, wn_position )
        output_space.get_neurons_in_circular_radius_with_distance(wn_position, radius) do |neuron, distance|
          updated_neuron_position = output_space.find_neuron_position(neuron)
          updated_neuron = neuron.learn(input_pattern, influence(distance, radius)*learning_rate)
          output_space.update_neuron_at_position(updated_neuron, updated_neuron_position)
        end
      end
      update!(iteration)
    end

    def create_umatrix
      @umatrix = UMatrix.new( input_patterns_for_wn, @output_space )
      @umatrixbla = UMatrixBla.new( @output_space )
      @umatrix.create_grid!
      @umatrixbla.create_grid!
    end

     def print_umatrixbla  file_name,max=@max,min=@min
      @umatrixbla.convert_to_colour!(@min,@max)
      @umatrixbla.print_matrix(5,5,file_name: file_name)
     end
     def print_umatrix  file_name,max=@max,min=@min
      @umatrix.convert_to_colour!
      @umatrix.print_matrix(5,5,file_name: file_name)
     end

    def bmus
      input_patterns.inject({}){ | hash, input |  hash[input] = @output_space[*@bmus_position[input]]; hash }
    end

    def bmus_to_csv(file_name)
      inst_bmus = bmus()
      # remove neuroni
      File.open(file_name, 'w'){ |file| @input_patterns.each{ |input_pattern| file.puts( "#{inst_bmus[input_pattern]},#{input_pattern}"  )}  }
    end

    def input_patterns_for_wn
      bmus.to_a.inject({}){ |hash, n| hash.has_key?(n.last) ? hash[n.last].push(n.first) : hash[n.last] = [n.first]; hash  }
    end

    def temporal_const_radius
      lamb(@epochs, @initial_radius)
      #@epochs/(Math::log(@radius))
    end

    def measures
        [@output_space.grid.size, @output_space.grid.first.size]
    end

    def update_bmus_position input_pattern, neuron_position
     @bmus_position[input_pattern] = neuron_position
    end

    def exec_and_print_steps! output_folder
      FileUtils::mkdir_p (File.join(Dir.pwd,'images', output_folder))
      aux = 0
      exec! do |som|
        file_name = "#{output_folder}\/#{aux}_radius_#{som.radius}_learning_rate_#{som.learning_rate.round(3)}"
        som.output_space.print_matrix(5,5, file_name: file_name + '_som.bmp' )
        som.create_umatrix
        print_umatrixbla( file_name + "_avg_#{@umatrixbla.grid.avg.round(3)}" + '_umatrixbla.bmp' )
        print_umatrix( file_name + "_avg_#{@umatrix.grid.avg.round(3)}" + '_umatrix.bmp' )
        aux += 1
      end
    end

    def exec! &block
      progress = ProgressBar.create(:title => "Will run #{@epochs} epochs", :starting_at => 0, :total => @epochs, :format => '%a %B %p%% %t')
      epochs.times{ |i| epoch(i + 1); progress.increment; yield( self, i + 1 ) if block_given? }
    end

    def update! iteration
      update_radius!(iteration) ; update_learning_rate!(iteration)
    end

    def update_radius! iteration
      raise 'Iteration Cannnot be Smaller than Zero' if iteration <= 0
      @radius = exponential_decay( initial_radius, temporal_const_radius, iteration ).round(0)
    end

    def update_learning_rate! iteration
      @learning_rate = exponential_decay( initial_learning_rate, @epochs/2, iteration )
    end

    def to_s
      @output_space.to_s + "\n" + @input_patterns.to_s
    end
  end
end
