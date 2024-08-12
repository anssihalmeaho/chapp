
ns main

import stdhttp
import stdjson
import stdjson
import stdfu
import stdpp
import stdpr

# set debug print functions
debug = call(stdpr.get-pr true)
debugpp = call(stdpr.get-pp-pr false)

do-post = proc(path data)
	_ _ body = call(stdjson.encode data):
	header = map('Content-Type' 'application/json')
	response = call(stdhttp.do 'POST' plus('http://localhost:9903' path) header body)
	get(response 'status-code')
end

do-get = proc(path)
	response = call(stdhttp.do 'GET' plus('http://localhost:9903' path) map())
	_ _ val = call(stdjson.decode get(response 'body')):
	val
end

setup = proc()
	tryl(list(
		call(do-post '/users' map('name' 'Ben'))
		call(do-post '/users' map('name' 'Bill'))
		call(do-post '/users' map('name' 'Bob'))

		call(do-post '/groups' map('name' 'A-team' 'owner' 'Ben'))
		call(do-post '/groups' map('name' 'B-team' 'owner' 'Ben'))
		call(do-post '/groups' map('name' 'C-team' 'owner' 'Bob'))

		call(do-post '/links' map('user' 'Ben' 'group' 'A-team'))
		call(do-post '/links' map('user' 'Ben' 'group' 'B-team'))
		call(do-post '/links' map('user' 'Bob' 'group' 'A-team'))
		call(do-post '/links' map('user' 'Bob' 'group' 'C-team'))
		call(do-post '/links' map('user' 'Bill' 'group' 'C-team'))
	))
end

make-name-by-id = func(users)
	pairlist = call(stdfu.apply vals(users) func(u) list(get(u 'id') get(u 'name')) end)
	call(stdfu.pairs-to-map pairlist)
end

make-id-by-name = func(users)
	pairlist = call(stdfu.apply vals(users) func(u) list(get(u 'name') get(u 'id')) end)
	call(stdfu.pairs-to-map pairlist)
end

reduce = func(users)
	call(stdfu.apply users func(user) get(user 'name') end)
end

verify-posting = proc(id-by-name)
	call(do-post plus('/posts/' 'A-team') map('msg' 'message to A:1'))
	call(do-post plus('/posts/' 'A-team') map('msg' 'message to A:2'))
	call(do-post plus('/posts/' 'B-team') map('msg' 'message to B:1'))
	call(do-post plus('/posts/' 'C-team') map('msg' 'message to C:1'))

	and(
		eq(
			call(debugpp 'posting: ' call(do-get plus('/posts/' get(id-by-name 'Ben'))) )
			list(
				map('msg' 'message to A:1')
				map('msg' 'message to A:2')
				map('msg' 'message to B:1')
			)
		)
		eq(
			call(debugpp 'posting: ' call(do-get plus('/posts/' get(id-by-name 'Bob'))) )
			list(
				map('msg' 'message to A:1')
				map('msg' 'message to A:2')
				map('msg' 'message to C:1')
			)
		)
		eq(
			call(debugpp 'posting: ' call(do-get plus('/posts/' get(id-by-name 'Bill'))) )
			list(
				map('msg' 'message to C:1')
			)
		)

		# and then there should be no more posts left
		eq(
			call(debugpp 'posting: ' call(do-get plus('/posts/' get(id-by-name 'Ben'))) )
			list()
		)
		eq(
			call(debugpp 'posting: ' call(do-get plus('/posts/' get(id-by-name 'Bob'))) )
			list()
		)
		eq(
			call(debugpp 'posting: ' call(do-get plus('/posts/' get(id-by-name 'Bill'))) )
			list()
		)
	)
end

verify = proc()
	users = call(do-get '/users')
	groups = call(do-get '/groups')
	links = call(do-get '/links')
	name-by-id = call(make-name-by-id users)
	id-by-name = call(make-id-by-name users)
	user-groups = map(
		'Ben' call(do-get plus('/groups/' get(id-by-name 'Ben')))
		'Bob' call(do-get plus('/groups/' get(id-by-name 'Bob')))
		'Bill' call(do-get plus('/groups/' get(id-by-name 'Bill')))
	)
	members = map(
		'A-team' call(reduce call(do-get plus('/users/' 'A-team')))
		'B-team' call(reduce call(do-get plus('/users/' 'B-team')))
		'C-team' call(reduce call(do-get plus('/users/' 'C-team')))
	)
	#print(members)

	and(
		# check users
		eq(len(users) 3)
		call(func()
			usernames = call(stdfu.apply vals(users) func(v) get(v 'name') end)
			and(
				in(usernames 'Ben')
				in(usernames 'Bill')
				in(usernames 'Bob')
		)
		end)

		# check groups
		eq(len(groups) 3)
		call(func()
			groupnames = keys(groups)
			and(
				in(groupnames 'A-team')
				in(groupnames 'B-team')
				in(groupnames 'C-team')
			)
		end)

		# check links
		eq(len(links) 5)
		and(
			in(links map('user' get(id-by-name 'Ben') 'group' 'A-team'))
			in(links map('user' get(id-by-name 'Ben') 'group' 'B-team'))
			in(links map('user' get(id-by-name 'Bob') 'group' 'A-team'))
			in(links map('user' get(id-by-name 'Bob') 'group' 'C-team'))
			in(links map('user' get(id-by-name 'Bill') 'group' 'C-team'))
		)

		# check groups by user
		and(
			eq(len(get(user-groups 'Ben')) 2)
			eq(len(get(user-groups 'Bob')) 2)
			eq(len(get(user-groups 'Bill')) 1)

			in(get(user-groups 'Ben') 'A-team')
			in(get(user-groups 'Ben') 'B-team')
			in(get(user-groups 'Bob') 'C-team')
			in(get(user-groups 'Bill') 'C-team')
		)

		# check users by group
		and(
			eq(len(get(members 'A-team')) 2)
			eq(len(get(members 'B-team')) 1)
			eq(len(get(members 'C-team')) 2)

			in(get(members 'A-team') 'Bob')
			in(get(members 'A-team') 'Ben')
			in(get(members 'B-team') 'Ben')
			in(get(members 'C-team') 'Bob')
			in(get(members 'C-team') 'Bill')
		)

		call(verify-posting id-by-name)
	)
end

main = proc()
	setup-ok setup-err = call(setup):
	if(setup-ok
		if(call(verify) 'Pass' 'Fail')
		plus('Fail: ' setup-err)
	)
end

endns

