
ns main

main = proc()
	import httprouter
	import stddbc
	import chapp-http
	import core
	import trails
	import logfile-store
	import dummy-in-mem

	store = call(dummy-in-mem.get-store)
	# NOTE. here permanent storage could be chosen instead by
	#       using logfile-store:
	#store = call(logfile-store.get-store 'oplog.txt')

	base = call(trails.init-base store)
	vob-base = call(get(base 'get-value-object'))
	if( eq(call(get(vob-base 'value')) map())
		call(proc()
			ok err = call(get(base 'commit') call(core.initial-data vob-base)):
			call(stddbc.assert ok err)
		end)
		'already initialized, no need to fill initial values'
	)

	routes = map(
		'GET' list(
				list(
					list('users')
					call(chapp-http.new-get-handler base 'users')
				)
				list(
					list('groups')
					call(chapp-http.new-get-handler base 'groups')
				)
				list(
					list('links')
					call(chapp-http.new-get-handler base 'links')
				)
				list(
					list('groups' ':id')
					call(chapp-http.new-get-all-groups-of-user base)
				)
				list(
					list('users' ':group-name')
					call(chapp-http.new-get-all-users-of-group base)
				)
				list(
					list('posts' ':id')
					call(chapp-http.new-get-posts-of-user base)
				)
			)

		'POST' list(
				list(
					list('users')
					call(chapp-http.new-add-handler base core.add-user)
				)
				list(
					list('groups')
					call(chapp-http.new-add-handler base core.add-group)
				)
				list(
					list('links')
					call(chapp-http.new-add-handler base core.add-link)
				)
				list(
					list('posts' ':group-name')
					call(chapp-http.new-add-post-to-group base)
				)
			)
	)

	my-error-logger = proc()
		import stdlog

		options = map(
			'prefix'       'my-HTTP-logger: '
			'separator'    ' : '
			'date'         true
			'time'         true
			'microseconds' true
			'UTC'          true
		)
		log = call(stdlog.get-default-logger options)
		proc(error-text)
			call(log error-text)
		end
	end

	router-info = map(
		'addr'         ':9903'
		'routes'       routes
		'error-logger' call(my-error-logger)
	)

	# create new router instance
	router = call(httprouter.new-router-v2 router-info)

	# get router procedures
	listen = get(router 'listen')
	shutdown = get(router 'shutdown')

	# signal handler for doing router shutdown
	import stdos
	sig-handler = proc(signum sigtext)
		_ = print('signal received: ' signum sigtext)
		call(shutdown)
	end
	call(stdos.reg-signal-handler sig-handler 2)

	# wait and serve requests (until shutdown is made)
	print('...serving...')
	call(listen)
	print('close: ' call(get(base 'close')))
end

endns

