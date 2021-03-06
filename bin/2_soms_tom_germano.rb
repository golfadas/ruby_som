#require 'pry'
require_relative '../lib/som.rb'
#require 'benchmark'

## Initialize the Output Space randomly
#  A) Initialize the SOM with 100 random neurons,
#     add 1000 random input patterns
som = SOM::SOM.new output_space_size: 15,
                   epochs: 600

## Randomly fill the output space
(225).times{ som.output_space.add(SOM::Neuron.new(3){ rand 0..255 }) }

## Generate 1500 random input patterns
som.min = 0
# Theorical max distance between two neurons is 255
# but, it will never be achieved, max distance shoould be defined on the first iteratioon
# where the umatrix is computed
#som.max = 255/(15 - 5 )
som.input_patterns = 2500.times.inject([]){ |arr| arr << Array.new(3){ rand(0..255) }; arr  }

som.exec_and_print_steps!('./results/test_folder_real_umatrix')

binding.pry
