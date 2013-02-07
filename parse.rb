require 'rubygems'
require 'json'
require 'pp'

input_filename = 'turnstile_130202.txt'

IS_SAMPLE_RUN = false

if IS_SAMPLE_RUN
	input_filename = 'sample_data.txt'
end

text = File.read(input_filename)

lines = text.split("\n")

all_data = {};

lines.each do |line|

	if line.strip != ""

		line_info = line.strip.split(",")

		unit = line_info[1].strip
		#control_area = line_info[0]
		#subunit_position = line_info[2]

		unit_data = all_data[unit] || {}

		samples = unit_data[:samples] || []

		last_sample = {}
		line_info[3..-1].each_with_index do |a,i|

			case i%5
			when 0:
			last_sample[:date] = a.strip
			when 1:
			last_sample[:time] = a.strip
			when 2:
			last_sample[:desc] = a.strip
			when 3:
			last_sample[:entries] = a.strip.to_i
			when 4:
			last_sample[:exits] = a.strip.to_i
			samples << last_sample
			last_sample = {}
			end

		end

		unit_data[:samples] = samples;
		unit_data[:control_area] = unit;

		all_data[unit] = unit_data;

	end
	
end

all_data.each do |k,v|
	# Sort the entries by date / time
	samples = v[:samples]
	samples.sort{|a,b| 
		if a[:date] == b[:date]
			a[:time] <=> b[:time] 
		else
			a[:date] <=> b[:date] 
		end
	}
	first_sample = samples[0]
	last_sample = samples[-1]
	# Get the cumulative entries and exits
	v[:total_entries] = last_sample[:entries].to_i - first_sample[:entries].to_i
	v[:total_exits] = last_sample[:exits].to_i - first_sample[:exits].to_i
	v[:samples] = samples
end

# pp all_data #.to_json

outp_filename = "parsed_data.json"
if IS_SAMPLE_RUN
	outp_filename = "parsed_data_sample.json"
end

File.open(outp_filename, 'w+') do |f| 
	f << all_data.to_json 
end