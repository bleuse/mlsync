#! /usr/bin/env ruby
# encoding: utf-8


require 'date'


# this is a very hackish way of translating gresille dates to a parsable format
# for ruby DateTime
def parse_date(date)
	_b_fr2en = {
		'janv.' => 'Jan',
		'févr.' => 'Feb',
		'mars'  => 'Mar',
		'avril' => 'Apr',
		'mai'   => 'May',
		'juin'  => 'Jun',
		'juil.' => 'Jul',
		'août'  => 'Aug',
		'sept.' => 'Sep',
		'oct.'  => 'Oct',
		'nov.'  => 'Nov',
		'déc.'  => 'Dec'
	}
	_b_regex = _b_fr2en.keys.map {|key| Regexp.escape(key)}
	_b_regex = '(' + _b_regex * '|' + ')'
	_b_regex = /#{_b_regex}/

	_b = date[_b_regex]
	date.sub!(_b, _b_fr2en[_b])

	return DateTime.strptime(date, '%d %b %Y %H:%M:%S')
end


class ExtranetDateParser
	def self.convert(value)
		return DateTime.strptime(value, '%Y-%m-%d')
	rescue ArgumentError
		return nil
	end
end

