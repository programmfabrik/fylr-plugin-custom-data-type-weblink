class CustomDataTypeLinkFacet extends FieldFacet

	initOpts: ->
		super()
		@addOpts
			field:
				mandatory: true
				check: Field

	requestFacetWithLimit: ->
		limit: @getLimit()
		field: @_field.fullName()+".tld"
		sort: "term"
		type: "term"

	getObjects: (key=@name(), data=@data()) ->
		data[key]?.terms or []

	renderObjectText: (object) ->
		object.term

	getObjectPath: (obj) ->
		[obj.term]

	name: ->
		"cdt_link"

	name: ->
		@_field.fullName()+".tld"

	requestSearchFilter: (obj) ->

		console.debug "requestSearchFilter:", obj

		bool: "must"
		fields: [ @_field.fullName()+".tld" ]
		type: "in"
		in: [ obj.term ]


