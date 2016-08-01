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

class Hash
	def slice(*keys)
		keys.each_with_object(self.class.new) do |k, hash|
			hash[k] = self[k] if has_key?(k)
		end
	end

	def includes_keys?(*keys)
		keys.all? {|key| self.key? key}
	end
end

