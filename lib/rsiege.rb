require 'net/http'
require 'openssl'
require_relative 'rsiege/uri_file_generator'

class RSiege

	def initialize(pool_size = 5)
		@pool_size = pool_size
		@jobs = Queue.new
	end

	def read_uris(filename)
		contents = File.new(filename).read
		@uris = []
		vars = {}
		contents.each_line do |s|
			next if s.match(/^([A-Za-z_]*)=(\S*)/) { |m| vars[m[1]] = m[2] }
			vars.each do |var, val|
				s.sub!((/\$\((#{var})\)/), val)
			end	
			str = s.split(' ')
			next if str.size < 1
			@uris.push({url: str[0], method: str[1], data: str[2]})
		end
		@uris
	end

	def get_urls
		@uris ||= read_urls
	end

	def send_requests(uris)	
		uris.each do |u|
			uri = URI(u[:url])			
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl=uri.scheme == 'https'
			# disable certificate verifying
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			@jobs.push({http: http, uri: uri, u: u})
		end
		run_jobs
	end

	def run_jobs
		(@pool_size).times.map { 
			Thread.new {
				while j = @jobs.pop(true)
					send_req(j[:http], j[:uri], j[:u])
				end				
			}
		}.each(&:join)
		rescue ThreadError
	end

	def send_req(http, uri, u)
		res = http.send_request(u[:method], uri.path, u[:data])
		file = File.open("tmp/http.log", "a+")
		file.write("#{u[:method]} #{u[:url]} #{u[:data]} >>> HTTP " + res.code + " >>> " + res.body + "\n\n")
		file.close
	end	

	def run_file(filename)
		send_requests(read_uris(filename))
	end

	def run
		URIFileGenerator.generate
		run_file('tmp/uris.txt')
	end
end