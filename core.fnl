
ns core

import stdpp
import stdfu
import stdmeta

/*
 data:
 =====

user id counter: int

users: map
- key: user id
- value: user info (map)

groups: map
- key: group name
- value: group info (map)

links: list of pairs, pair = map:
- 'group': group name
- 'user': user id

posts: map: user-id => list of posts
- post is map

*/

initial-data = func(value-ob)
	call(stdfu.chain value-ob list(
		func(v) call(get(v 'set-to') list('user-id-counter') 10) end
		func(v) call(get(v 'set-to') list('users') map()) end
		func(v) call(get(v 'set-to') list('groups') map()) end
		func(v) call(get(v 'set-to') list('links') list()) end
		func(v) call(get(v 'set-to') list('posts') map()) end
	))
end

# get all messages for given user-id
get-posts-of-user = func(store user-id)
	get-from-store = get(store 'get-from')

	found users-posts = call(get-from-store list('posts' user-id)):
	if(found
		call(func()
			next-value = call(get(store 'set-to') list('posts' user-id) list())
			list(users-posts next-value)
		end)
		list(list() store)
	)
end

# give user-id based on user name
user-id-by-name = func(users username)
	matched = call(stdfu.filter users func(_ user) eq(get(user 'name') username) end)
	case(len(matched)
		0 list(false '')
		1 list(true head(keys(matched)))
		error('owner found multiple times: should not happen')
	)
end

# add message for given group
add-post = func(store group-name post)
	get-from-store = get(store 'get-from')

	add-to-one-user = func(uid posts)
		if(in(posts uid)
			call(func()
				prev-posts = get(posts uid)
				put(del(posts uid) uid append(prev-posts post))
			end)

			put(posts uid list(post))
		)
	end

	is-valid-post = func(posting)
		post-schema = list('map' map(
			'msg' list(list('required') list('type' 'string') list('doc' 'message in posting'))
		))
		ok _ = call(stdmeta.validate post-schema posting):
		ok
	end

	# TODO: validate post format
	cond(
		# validating input post data
		not(call(is-valid-post post))
		list(false 'invalid post' store)

		call(func()
			_ links = call(get-from-store list('links')):
			_ posts = call(get-from-store list('posts')):
			matched-links = call(stdfu.filter
				links
				func(link) eq(get(link 'group') group-name) end
			)
			user-ids = call(stdfu.apply matched-links func(link) get(link 'user') end)
			new-posts = call(stdfu.foreach user-ids add-to-one-user posts)
			next-value = call(get(store 'set-to') list('posts') new-posts)
			list(true '' next-value)
		end)
	)
end

# give all users which belong to given group
get-all-users-of-group = func(store group-name)
	get-from-store = get(store 'get-from')

	_ links = call(get-from-store list('links')):
	matched-links = call(stdfu.filter links func(link)
		eq(get(link 'group') group-name)
	end)
	call(stdfu.apply matched-links func(link)
		uid = get(link 'user')
		call(func()
			_ username = call(get-from-store list('users' uid)):
			username
		end)
	end)
end

# give all groups to which user (by user-id) belongs to
get-all-groups-of-user = func(store user-id)
	get-from-store = get(store 'get-from')

	_ links = call(get-from-store list('links')):
	_ users = call(get-from-store list('users')):
	id-found user = getl(users user-id):
	if(id-found
		call(func()
			matched-links = call(stdfu.filter links func(link)
				eq(get(link 'user') user-id)
			end)
			call(stdfu.apply
				matched-links
				func(link) get(link 'group') end
			)
		end)
		list()
	)
end

# add link between user and group (adding user to group)
add-link = func(store link-info)
	get-from-store = get(store 'get-from')

	# validates data format for link
	is-valid-link-info = func(link)
		link-schema = list('map' map(
			'user' list(list('required') list('type' 'string') list('doc' 'Users name'))
			'group' list(list('required') list('type' 'string') list('doc' 'Group name'))
		))
		ok _ = call(stdmeta.validate link-schema link):
		ok
	end

	# return true if link exists
	link-exists = func(value new-link)
		_ users = call(get-from-store list('users')):
		found uid = call(user-id-by-name users get(new-link 'user')):

		if(found '' error('user not found'))
		_ current-links = call(get-from-store list('links')):
		in(current-links map(
			'group' get(new-link 'group')
			'user'  uid
		))
	end

	cond(
		# validating input user data
		not(call(is-valid-link-info link-info))
		list(false 'invalid link info' store)

		# checking that such user exists
		call(func()
			_ users = call(get-from-store list('users')):
			not(call(user-exists vals(users) get(link-info 'user')))
		end)
		list(false 'user does not exist' store)

		# checking that such group exists
		call(func()
			_ groups = call(get-from-store list('groups')):
			not(call(group-exists groups get(link-info 'group')))
		end)
		list(false 'group does not exist' store)

		# check that similar link is not yet there
		call(link-exists store link-info)
		list(false 'same link exists already' store)

		# ok lets add
		call(func()
			_ links = call(get-from-store list('links')):
			_ users = call(get-from-store list('users')):
			_ uid = call(user-id-by-name users get(link-info 'user')):
			new-link = map(
				'group' get(link-info 'group')
				'user'  uid
			)
			next-value = call(get(store 'set-to') list('links') add(links new-link))
			list(true '' next-value)
		end)
	)
end

# checks if user with same name is already there
user-exists = func(users username)
	call(stdfu.applies-for-any users
		func(user)
			eq(get(user 'name') username)
		end
	)
end

# checks if group with same name is already there
group-exists = func(group new-group-name)
	in(group new-group-name)
end

# add new user
add-user = func(store user-info)
	get-from-store = get(store 'get-from')

	# validates data format for user
	is-valid-user-info = func(user)
		user-schema = list('map' map(
			'name' list(list('required') list('type' 'string') list('doc' 'Users name'))
		))
		ok _ = call(stdmeta.validate user-schema user):
		ok
	end

	_ users = call(get-from-store list('users')):
	cond(
		# validating input user data
		not(call(is-valid-user-info user-info))
		list(false 'invalid user info' store)

		# preventing same user name exist twice
		call(func()
			name-checker = func(_ uinfo)
				eq(get(uinfo 'name') get(user-info 'name'))
			end
			matches = call(stdfu.filter users name-checker)
			not(empty(matches))
		end)
		list(false 'user exists already' store)

		# ok lets add
		call(func()
			_ prev-user-id = call(get-from-store list('user-id-counter')):
			next-user-id = plus(prev-user-id 1)
			next-uid-str = str(next-user-id)
			uinfo = put(user-info 'id' next-uid-str)
			new-store = call(stdfu.chain store list(
				func(v) call(get(v 'set-to') list('user-id-counter') next-user-id) end
				func(v) call(get(v 'set-to') list('users' next-uid-str) uinfo) end
			))
			list(true '' new-store)
		end)
	)
end

# add new group
add-group = func(store group-info)
	get-from-store = get(store 'get-from')

	# validates data format for group
	is-valid-group-info = func(group)
		group-schema = list('map' map(
			'name' list(list('required') list('type' 'string') list('doc' 'Group name'))
			'owner' list(list('required') list('type' 'string') list('doc' 'Group owner name'))
		))
		ok _ = call(stdmeta.validate group-schema group):
		ok
	end

	# validates group name
	is-valid-group-name = func(group-name)
		import stdstr

		call(stdfu.chain group-name list(
			func(s) call(stdstr.replace s '-' '') end
			func(s) call(stdstr.replace s '_' '') end
			func(s) call(stdstr.is-alpha s) end
		))
	end

	# finds group owner id
	find-owner-id = func(users owner)
		matched = call(stdfu.filter users func(_ user) eq(get(user 'name') owner) end)
		case(len(matched)
			0 list(false '')
			1 list(true head(keys(matched)))
			error('owner found multiple times: should not happen')
		)
	end

	call(func() # btw, function call just because having own namespace there
		_ groups = call(get-from-store list('groups')):
		cond(
			# validating input group data
			not(call(is-valid-group-info group-info))
			list(false 'invalid group info' store)

			# validating group name
			not(call(is-valid-group-name let(group-name get(group-info 'name'))))
			list(false 'invalid group name' store)

			# preventing same group name existing twice
			call(group-exists groups group-name)
			list(false 'group exists already' store)

			# ok lets add
			call(func()
				_ users = call(get-from-store list('users')):
				owner-found owner-id = call(find-owner-id users get(group-info 'owner')):
				if(owner-found
					call(func()
						next-group = put(del(group-info 'owner') 'id' owner-id)
						next-value = call(get(store 'set-to') list('groups' group-name) next-group)
						list(true '' next-value)
					end)
					list(false 'group owner not found' store)
				)
			end)
		)
	end)
end

endns

