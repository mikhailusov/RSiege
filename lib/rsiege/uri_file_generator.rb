class URIFileGenerator

	class << self
		def generate(uri = '', common_params = '', count = '', diff_params = {}, method = 'POST', filename = 'tmp/uris.txt')
			uri = "https://52.91.159.173/api"
			count = 1
			diff_params = {"OrderNumber" => "Siege_a0001"}

			requests = []
			count.times { |c| requests.push(diff_params.map{|k, v| "&#{k}=#{v.succ!}"}.join) }
			create_file(file_template(uri, method, common_params, requests), filename)
		end

		def create_file(content, filename)
			f = File.new(filename, "w+")
			f.write(content)
			f.close  
		end

		def file_template(uri, method, common_params, requests)
<<EOF
URL=#{uri}
COMMON_PARAMS=#{common_params}

#{requests.map{|r| "$(URL) #{method} $(COMMON_PARAMS)" + r}.join("\n")}
EOF
		end
	end
end

