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

