ResqueUnit
==========

This gem/plugin will hopefully make it easier to test resque job
queueing in your applications.


Example
=======

    Resque.enqueue(Job)
    assert_queued(Job)

It'll be cooler later, I swear.

Copyright (c) 2010 Justin Weiss, released under the MIT license
