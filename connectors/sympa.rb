# encoding: utf-8

# Copyright © 2016
# Contributed by Raphaël Bleuse <raphael@bleuse.net>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'httpi'
require 'nokogiri'
require 'savon' # SOAP abstraction gem

require_relative 'helper.rb'
require_relative '../helpers/patches/hash'


class Sympa
	extend Savon::Model


	class SympaError < StandardError; end


	def initialize(base_url, wsdl='wsdl')
		self.class.client(
			wsdl: base_url + '/' + wsdl,
			namespace: 'urn:sympasoap',
			raise_errors: false
		)
		@base_url = base_url
		@session = nil
	end


	operations :add, :info, :login, :review


	def add(listname, email, gecos=nil, quiet=false)
		response = super(
			message: {
				listname: listname,
				email: email,
				gecos: gecos,
				quiet: quiet
			},
			cookies: @session
		)
		check_response response
	end


	def info(listname)
		response = super(
			message: {listname: listname},
			cookies: @session
		)
		check_response response
		return response.body[:info_response].values[0]
	end


	def login(login, passwd)
		response = super(message: {email: login, password: passwd})
		check_response response
		@session = HTTPI::Cookie.new(
			response.http.headers['set-cookie2']
		)
	end


	def review(listname)
		response = super(
			message: {listname: listname},
			cookies: @session
		)
		check_response response
		return response.body[:review_response][:return][:item]
	end


	def dump_logs(listname, chunksize=250)
		# parsing of logs is hardcoded here, maybe there is a better
		# way to do it… hackish?
		_columns = [
			[:date,    'td[1]/text()'],
			[:action,  'td[3]/text()'],
			[:params,  'td[4]/text()'],
			[:email,   'td[5]/text()'], # target mail address
			[:msgid,   'td[6]/text()'],
			[:status,  'td[7]/text()'],
			[:errtype, 'td[8]/text()'],
			[:user,    'td[9]/text()'], # origin of the action
			[:ip,      'td[10]/text()']
		]

		pagenum = 1
		logs = []

		loop do
			# build request for page pagenum
			request = HTTPI::Request.new
			request.url = "#{@base_url}/viewlogs/#{listname}/#{pagenum}/#{chunksize}/email"
			request.set_cookies(@session)

			# retrieve raw html
			response = HTTPI::get(request)
			html_doc = Nokogiri::HTML(response.body)

			# exit if there are no logs (no more pages)
			break if html_doc.at('//div[@id="ErrorBlock"]')

			# parse raw logs
			raw_logs = html_doc.xpath('//table[@summary="logs table"]/tr')
			parsed_logs = raw_logs.map do |row|
				detail = {}
				_columns.each do |name, xpath|
					value = row.at(xpath).to_s.strip
					detail[name] = value unless value.empty?
				end
				detail unless detail.empty?
			end
			parsed_logs.compact!
			parsed_logs.map do |row|
				row[:date] = parse_date(row[:date]) if row[:date]
				row[:action] = row[:action].to_sym if row[:action]
			end

			# gather new logs
			logs += parsed_logs

			pagenum += 1
		end

		return logs
	end


	def get_signoff(listname)
		raw_logs = dump_logs(listname)
		valid_after = raw_logs.min{|a,b| a[:date] <=> b[:date]}[:date]
		off = raw_logs.select do |row|
			[:del, :signoff].include? row[:action]
		end
		off.map!{|row| row.slice(:email, :date)}

		return {valid_after: valid_after, off: off}
	end


	def check_response(response)
		if response.body.key?(:fault)
			raise SympaError, response.body[:fault][:faultstring]
		end
	end
	private :check_response
end

