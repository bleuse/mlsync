#! /usr/bin/env ruby
# encoding: utf-8


require 'savon' # SOAP abstraction gem


class Sympa
	extend Savon::Model


	class SympaError < StandardError; end


	def initialize(wsdl)
		self.class.client(
			wsdl: wsdl,
			namespace: 'urn:sympasoap',
			raise_errors: false
		)
		@session = nil
	end

	operations :add, :info, :login, :review
=begin
	operations :add, :am_i, :authenticate_and_run, :authenticate_remote_app_and_run, :cas_login, :check_cookie, :close_list, :complex_lists, :complex_which, :create_list, :del, :get_user_email_by_cookie, :info, :lists, :login, :review, :signoff, :subscribe, :which
=end

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

	def check_response(response)
		if response.body.key?(:fault)
			raise SympaError, response.body[:fault][:faultstring]
		end
	end
	private :check_response
end

