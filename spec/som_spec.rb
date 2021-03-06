require_relative '../lib/som'
include SOM

describe SOM do
  before :each do
    @som = SOM::SOM.new learning_rate: 0.6
    @som.input_patterns = Matrix.new([[1,1,0,0],[0,0,0,1],[1,0,0,0],[0,0,1,1]])
    [ SOM::Neuron.new( [0.2,0.6,0.5,0.9]  ),
      SOM::Neuron.new( [0.8,0.4,0.7,0.3]  ) ].each{ |neuron| @som.output_space.add( neuron  )  }
  end

  ## Must find a way to test this without getting random trainning values..
  ## Probably by creating the bmus by hand
  #describe 'bmus_to_csv' do
    #it "returns a csv file with the list of neurons and their corresponding input pattern" do
      #@som.epoch
      #@som.bmus_to_csv('/tmp/bmus_list.csv')
      #File.read('/tmp/bmus_list.csv').split("\n").should include(
        #"[000.490,000.110,000.440,000.51],[1, 1, 0, 0]",
        #"[000.210,000.070,000.630,000.80],[0, 0, 0, 1]",
        #"[000.490,000.110,000.440,000.51],[1, 0, 0, 0]",
        #"[000.210,000.070,000.630,000.80],[0, 0, 1, 1]")
    #end
  #end

  describe 'bmus' do
    it "returns a list of input patterns and their best matching units (BMUs)" do
      @som.epoch
      @som.input_patterns.each do |input|
        @som.bmus[input].should eql(@som.output_space.find_winning_neuron(input))
      end
    end
  end

  describe 'bmus_position' do
    it 'returns a list of the input patterns, and the location of the BMUs' do
      @som.epoch
      @som.bmus_position.each_pair do |input, bmu_pos|
        winning_neuron = @som.output_space.find_winning_neuron(input)
        @som.output_space.find_neuron_position(winning_neuron).should eql(bmu_pos)
      end
    end
  end

  describe '#measures' do
    it "returns an array with width and height of the output_space" do
      @som.measures.should eql([4,4])
      @som.output_space.grid = [ [[1,2],[3,4]],
                                 [[5,6],[7,8]],
                                 [[9,10],[11,12]]]
      # 3 is height, 2 is width
      @som.measures.should eql([3,2])
    end
  end

  describe '#temporal_const' do
    it "returns the som temporal const (lambda)" do
      @som.temporal_const_radius.round(0).should eql(144)
    end
  end

  describe '#input_patterns_for_wn' do
    it "returns an hash with a list of the input patterns corresponding to each winning neuron" do
      @som.epoch
      @som.input_patterns_for_wn.each_pair do |bmu, input_patterns|
        input_patterns.each{ |input_pattern| @som.output_space.find_winning_neuron(input_pattern).should eql(bmu)}
      end
    end
  end

  describe '#update_learning_rate' do
    it "decreases the learning_rate based on the number of epochs that run" do
      @som = SOM::SOM.new output_space_size: 10, epochs:3
      @som.input_patterns = Matrix.new([[1,1,0,0],[0,0,0,1],[1,0,0,0],[0,0,1,1]])
      [ SOM::Neuron.new( [0.2,0.6,0.5,0.9]  ),
        SOM::Neuron.new( [0.8,0.4,0.7,0.3]  ) ].each{ |neuron| @som.output_space.add( neuron  )  }
      @som.exec! do |som_state, i|
        instance_variable_set("@learning_rate_#{i}",som_state.learning_rate)
      end
      @learning_rate_1.should be >= @learning_rate_2
      @learning_rate_2.should be >= @learning_rate_3
      @learning_rate_1.should be_a Float
      @learning_rate_2.should be_a Float
      @som.learning_rate.should be_a Float
    end
  end

  describe '#update_radius' do
    it "dcreases the radius based on the number of epochs that run" do
      @som = SOM::SOM.new output_space_size: 11, epochs:3
      @som.input_patterns = Matrix.new([[1,1,0,0],[0,0,0,1],[1,0,0,0],[0,0,1,1]])
      [ SOM::Neuron.new( [0.2,0.6,0.5,0.9]  ),
        SOM::Neuron.new( [0.8,0.4,0.7,0.3]  ) ].each{ |neuron| @som.output_space.add( neuron  )  }
      aux = 1
      @som.exec! do |som_state|
        instance_variable_set("@radius_#{aux}",som_state.radius)
        aux += 1
      end
      @radius_1.should be >= @radius_2
      @radius_2.should be >= @radius_3
    end
  end

end


