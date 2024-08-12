
ns chapp-http

import stdhttp
import stdjson
import stddbc

make-response = proc(data)
	ok err response = call(stdjson.encode data):
	call(stddbc.assert ok err)
	map(
		'header' map('Content-Type' 'application/json')
		'body'   response
	)
end

new-get-handler = func(base data-name)
	proc(w r)
		vob = call(get(base 'get-value-object'))
		_ data = call(get(vob 'get-from') list(data-name)):
		call(make-response data)
	end
end

new-add-handler = func(base action-proc)
	proc(w r params)
		ok err user-info = call(stdjson.decode get(r 'body')):
		call(stddbc.assert ok err)

		store = call(get(base 'get-value-object'))
		action-ok action-err next-store = call(action-proc store user-info):

		if(action-ok
			call(proc()
				cok cerr = call(get(base 'commit') next-store):
				call(stddbc.assert cok cerr)
			end)
			print('action error: ' action-err)
		)
		map('status' if(action-ok 201 400))
	end
end

new-get-all-groups-of-user = func(base)
	import core
	proc(w r params)
		has-id user-id = getl(params ':id'):
		call(stddbc.assert has-id 'no user id available')

		store = call(get(base 'get-value-object'))
		data = call(core.get-all-groups-of-user store user-id)

		call(make-response data)
	end
end

new-get-all-users-of-group = func(base)
	import core
	proc(w r params)
		has-group-name group-name = getl(params ':group-name'):
		call(stddbc.assert has-group-name 'no group name available')

		store = call(get(base 'get-value-object'))
		data = call(core.get-all-users-of-group store group-name)

		call(make-response data)
	end
end

new-get-posts-of-user = func(base)
	import core
	proc(w r params)
		has-id user-id = getl(params ':id'):
		call(stddbc.assert has-id 'no user id available')

		store = call(get(base 'get-value-object'))
		data next-store = call(core.get-posts-of-user store user-id):
		call(proc()
			cok cerr = call(get(base 'commit') next-store):
			call(stddbc.assert cok cerr)
		end)

		call(make-response data)
	end
end

new-add-post-to-group = func(base)
	import core
	proc(w r params)
		has-group-name group-name = getl(params ':group-name'):
		call(stddbc.assert has-group-name 'no group name available')
		ok err post = call(stdjson.decode get(r 'body')):
		call(stddbc.assert ok err)

		store = call(get(base 'get-value-object'))
		action-ok action-err next-store = call(core.add-post store group-name post):
		if(action-ok
			call(proc()
				cok cerr = call(get(base 'commit') next-store):
				call(stddbc.assert cok cerr)
			end)
			print('post msg error: ' action-err)
		)

		map('status' if(action-ok 201 400))
	end
end

endns

