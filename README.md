# chapp
Example messaging application.
Implemented in [FunL](https://github.com/anssihalmeaho/funl).

## Installing
Fetch repository with `--recursive` option (so that needed submodules are included):

```
git clone --recursive https://github.com/anssihalmeaho/chapp.git
```

## What is chapp
It's example application to implement minimal messaging service.
It's just CRUD type of HTTP service which stores user and group (of users)
information and stores posts/messages to users in groups.

Basic concepts:

* **user**: messaging service user, identified by name (unique **user-id** generated for user)
* **group**: identified by name, has owning user
* **link**: linkage between user and group (pair), means that user belongs to group
* **post**: posting (or message) sent to certain group, read/consumed by group members

Purpose of chapp is to demonstrate two things:

1. dividing application to pure functional domain part and to impure external I/O part
2. how to use data in pure functional way but sametime having effcient permanent storage for it

Especially using [trails](https://github.com/anssihalmeaho/trails) module for data processing is purpose of this example.
It enables pure domain part being able to view all stored data as such and produce new version from it which is eventually written to permanent storage by impure part of code.

Implementation is missing many parts which would be required for real application (security, modifying and deleting users, groups and links etc.) as well as scaling but it works as demonstration for data usage.

Pure functional domain part of code (**core** module) does basically two kind of things:

* validates input data (from request)
* implements domain data related logic

By being able see all data and process it to make next version of whole data enables
domain logic part handling most of the functionality (in pure FP way) and impure I/O play minor part there.
Also data consistency is non-problem as it's immutable snapshot.

## API's
Following HTTP API's are provided by chapp.

### POST /users
Adds user.

### POST /groups
Adds group.

### POST /links
Add user to group.

### POST /posts/:group-name
Sends message to given group (group name as **:group-name**).

### GET /users
Get all users.

### GET /groups
Get all groups.

### GET /links
Get all links between users and groups.

### GET /groups/:user-id
Get all groups to which given user belongs to (user identified by **:user-id**).

### GET /users/:group-name
Get all users which belong to given group (group name given as **:group-name**).

### GET /posts/:user-id
Fetch all messages of given user (user identified by **:user-id**).

## Running chapp
Start chapp:

```
funla chapp.fnl
```

Run integration tests:

```
funla verifier.fnl
```

Prints:
```
'Pass'
```

chapp listens port 9903 for incoming request (http).

Example of manually sending message to group:

```
curl -X POST -d '{"msg": "Hi There !"}' http://localhost:9903/posts/A-team
```

And fetching users message:

```
 curl http://localhost:9903/posts/11

 [{"msg": "Hi There !"}]
```

## Changing permanent storage implementation
Dummy mock implementation is used by default for storage interface, see **chapp.fnl** line:

```
store = call(dummy-in-mem.get-store)
```

To use log file storage implementation that line needs to taken away/commented and
take into use following commented line in **chapp.fnl**:

```
#store = call(logfile-store.get-store 'oplog.txt')
```

After that chapp remembers all stored data even if it's restarted.
