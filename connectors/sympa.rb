#! /usr/bin/env ruby
# encoding: utf-8


require 'httpi'
require 'nokogiri'
require 'savon' # SOAP abstraction gem

require_relative 'helper.rb'

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

	def dump_logs(listname)
		request = HTTPI::Request.new
		request.url = @base_url
		request.set_cookies(@session)
		request.body = {
			list: listname,
			action: 'viewlogs',
			target_type: 'target_email',
		}

		response = HTTPI::post(request)
		html_doc = Nokogiri::HTML(response.body)

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

		log_table =
			html_doc.xpath('//table[@summary="logs table"]/tr')
		logs = log_table.map do |row|
			detail = {}
			_columns.each do |name, xpath|
				value = row.at(xpath).to_s.strip
				detail[name] = value unless value.empty?
			end
			detail unless detail.empty?
		end
		logs.compact!
		logs.map do |row|
			row[:date] = parse_date(row[:date]) if row[:date]
			row[:action] = row[:action].to_sym if row[:action]
		end

		return logs
	end

	def check_response(response)
		if response.body.key?(:fault)
			raise SympaError, response.body[:fault][:faultstring]
		end
	end
	private :check_response
end

