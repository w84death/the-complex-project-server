# ------------------------------------------------------------------------------
# P1X Godot Multiplayer Server V0.99
#             f o r 
#    - The Complex Project -
#
# (c) 2020 P1X / Krzysztof Jankowski 
# ------------------------------------------------------------------------------


extends MainLoop
var quit = false

export var PORT = 9666
var _server = WebSocketServer.new()
var players_list = []
var MOTD = 'Welcome to the P1X Game Server.\nTCPServer CLI V%s.\nVisit p1x.in and krzysztofjankowski.com\nMost important - have fun!' % 0.99



# ----------------------------- CONNECTION -------------------------------------


func _initialize():
	print("Message Of The Day is:")
	print("----------------------------------------")
	print(MOTD)
	print("----------------------------------------")
	print("Connecting events...")
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	_server.connect("data_received", self, "_on_data")
	print("OK")
	print("Starting server...")
	var err = _server.listen(PORT)
	if err != OK:
		print("...ERROR")
		print("Unable to start server")
		#set_process(false)
	else:
		print("OK")
		print("Server started at port " + str(PORT))
	print("----------------------------------------")

func _input_event(event):
	if event is InputEventKey and event.pressed and !event.echo:
		if event.scancode == KEY_ESCAPE:
			quit = true
			print("Killing server...")
	if event is InputEventMouseButton:
		quit = true
			
func _finalize():
	print("OK, bye!")
	
func _connected(id, _proto):
	print("Player %d connected." % [id])
	add_player(id)
	
func _close_request(id, code, reason):
	print("Player %d disconnecting with code: %d, reason: %s" % [id, code, reason])

func _disconnected(id, was_clean = false):
	print("Player %d disconnected, clean: %s" % [id, str(was_clean)])
	remove_player(id)
	for player in players_list:
		var payload = 'DIS/%s' % [id]
		_server.get_peer(player.id).put_packet(payload.to_utf8())

func _idle(_delta):
	_server.poll()
	return quit

func _exit_tree():
	_server.stop()


# ----------------------------- NET DATA ---------------------------------------


func _on_data(id):
	var payload
	var pkt = _server.get_peer(id).get_packet().get_string_from_utf8().split("/", true)
	print("%d -> %s" % [id, pkt[0]])
	
	if pkt[0] == "JOIN":
		print("%d -> joins" % id)
		payload = 'YOUR_ID/%s' % id
		_server.get_peer(id).put_packet(payload.to_utf8())
		
		payload = 'MOTD/%s' % MOTD
		_server.get_peer(id).put_packet(payload.to_utf8())
		
		payload = 'NEW_JOIN/%s/%s/%s/%s' % [id, '0.0,0.0,0.0', '0', 'false']
		for player in players_list:
			if player.id != id:
				_server.get_peer(player.id).put_packet(payload.to_utf8())
		
	if pkt[0] == "POS":
		for player in players_list:
			update_last_pos(id, pkt[1], pkt[2])
			payload = 'POS/%s/%s/%s' % [id, pkt[1], pkt[2]]
			if player.id != id:
				_server.get_peer(player.id).put_packet(payload.to_utf8())

	if pkt[0] == "GET_PLAYERS_LIST":
		print("%d -> asks for players list" % id)
		for player in players_list:
			if player.id != id:
				payload = 'NEW_JOIN/%s/%s/%s/%s' % [player.id, player.last_pos, player.last_rot, player.flashlight]
				_server.get_peer(id).put_packet(payload.to_utf8())
			
	if pkt[0] == "FLASHLIGHT":
		print("%d -> flashlight %s" % [id, pkt[1]])
		for player in players_list:
			payload = 'FLASHLIGHT/%s/%s' % [id, pkt[1]]
			if player.id != id:
				_server.get_peer(player.id).put_packet(payload.to_utf8())


# ----------------------------- HELPERS ---------------------------------------


func add_player(id):
	var new_player = {
		'id': id,
		'name': 'annonymous',
		'last_pos': '0.0,0.0,0.0',
		'last_rot': '0',
		'flashlight': false
	}
	players_list.append(new_player)
	refresh_player_list()
	
func remove_player(id):
	var f = 0
	for p in players_list:
		if p.id == id:
			players_list.remove(f)
		f += 1
	refresh_player_list()
	
func update_last_pos(id, pos, rot):
	for p in players_list:
		if p.id == id:
			p.last_pos = pos
			p.last_rot = rot

func refresh_player_list():
	var i = 1
	print("\nUpdated players list:\n")
	if players_list.size() < 1:
		print("-- no players --")
	else:
		for player in players_list:
			print("%s> %s (%s)\n" % [i, player.name, player.id])
			i += 1
