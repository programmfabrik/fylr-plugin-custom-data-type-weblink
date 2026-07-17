###
 * easydb-custom-data-type-link
 * Copyright (c) 2013 - 2016 Programmfabrik GmbH
 * MIT Licence
 * https://github.com/programmfabrik/coffeescript-ui, http://www.coffeescript-ui.org
###

class CustomDataTypeLink extends CustomDataType
	getCustomDataTypeName: ->
		# "custom:solution.custom-types-test.types.link"
		"custom:base.custom-data-type-link.link"

	# returns a map for search tokens, containing name and value strings.
	getQueryFieldBadge: (data) =>
		# console.error "getQueryFieldBadge", data
		if data["#{@name()}:unset"]
			value = $$("text.column.badge.without")
		else if data["#{@name()}:has_value"]
			value = $$("field.search.badge.has_value")
		else
			value = data[@name()]

		name: @nameLocalized()
		value: value

	getCustomDataTypeNameLocalized: ->
		$$("custom.data.type.link.name")

	isEmpty: (data, top_level_data, opts={}) ->
		if opts.mode == "expert"
			# check plain input in search
			return CUI.util.isEmpty(data[@name()]?.trim())

		if data[@name()]?.url
			false
		else
			true

	getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
		tags = []
		pre = "custom.data.type.link.setting.schema.rendered_options."

		if custom_settings.title?.type
			tags.push(pre+"title."+custom_settings.title.type)

		if custom_settings.add_timestamp?.value
			tags.push(pre+"with_date")
		else
			tags.push(pre+"without_date")

		($$(tag) for tag in tags)


	initData: (data) ->
		if not data[@name()]
			cdata = {}
			data[@name()] = cdata
		else
			cdata = data[@name()]

		if not cdata.url
			cdata.url = ""

		# We add the template data, if we have any.
		if data._template?[@name()]
			cdata._template = data._template[@name()]

		cdata

	renderFieldAsGroup: (data, top_level_data, opts) ->
		if opts.fieldRenderType == 'editor' and @supportsInline()
			return true
		else
			return false

	supportsFacet: ->
		true

	getFacet: (opts) ->
		opts.field = @
		new CustomDataTypeLinkFacet(opts)

	# provide a sort function to sort your data
	getSortFunction: ->
		(a, b) =>
			CUI.util.compareIndex(a[@name()]?.hostname or 'zzz', b[@name()]?.hostname or 'zzz')

	# returns markup to display in expert search
	renderSearchInput: (data, opts={}) ->
		return new SearchToken(
			column: @
			data: data
			fields: opts.fields
		).getInput().DOM

	getFieldNamesForSearch: ->
		@getFieldNames()

	getFieldNamesForSuggest: ->
		@getFieldNames()

	getFieldNames: ->

		field_names = [
			@fullName()+".tld"
			@fullName()+".url"
			@fullName()+".text_plain"
		]
		if not ez5.version("6")
			for lang in ez5.session.getPref("search_languages")
				field_names.push(@fullName()+".text."+lang)
		else
			field_names.push(@fullName()+".text")

		field_names

	renderEditorInput: (data, top_level_data, opts) ->
		cdata = @initData(data)

		if @supportsInline()
			@__renderEditorInputInline(cdata)
		else
			@__renderEditorInputPopover(cdata)

	supportsStandard: ->
		true

	supportsPrinting: ->
		true

	supportsInline: ->
		@getCustomMaskSettings().editor_style?.value != "popover"

	supportsTimestamp: ->
		@getCustomSchemaSettings().add_timestamp?.value

	getTitleType: ->
		@getCustomSchemaSettings().title?.type or "text-l10n"

	__renderEditorInputPopover: (cdata) ->

		layout = new CUI.HorizontalLayout
			left: {}
			right:
				content:
					loca_key: "custom.data.type.link.edit.button"
					onClick: (ev, btn) =>
						@showEditPopover(cdata, btn, layout)

		@__updateDisplayLink(cdata, layout)
		layout


	__renderEditorInputInline: (cdata) ->

		fields = @__getEditorFields(cdata)

		btn = @__renderButtonByData(cdata)
		preview =
			name: "preview"
			type: DataFieldProxy
			form:
				label: $$("custom.data.type.link.preview.label")
			element: btn

		fields.push(preview)

		form = new CUI.Form
			data: cdata
			maximize_horizontal: true
			onDataChanged: =>
				previewField = form.getFieldsByName("preview")[0]
				previewField.replace(@__renderButtonByData(cdata))
				@__triggerFormChanged(form)
			fields: fields
		.start()


		form

	__updateDisplayLink: (cdata, layout) ->
		btn = @__renderButtonByData(cdata)
		layout.replace(btn, "left")

	__triggerFormChanged: (form) ->
		CUI.Events.trigger
			node: form
			type: "editor-changed"

	# returns a search filter suitable to the search array part
	# of the request, the data to be search is in data[key] plus
	# possible additions, which should be stored in key+":<additional>"

	getSearchFilter: (data, key=@name()) ->
		if data[key+":unset"]
			filter =
				type: "in"
				fields: [ @fullName()+".url" ]
				in: [ null ]
			filter._unnest = true
			filter._unset_filter = true
			return filter

		else if data[key+":has_value"]
			return @getHasValueFilter(data, key)

		filter = super(data, key)
		if filter
			return filter

		if CUI.util.isEmpty(data[key])
			return

		val = data[key]
		[str, phrase] = Search.getPhrase(val)

		switch data[key+":type"]
			when "token", "fulltext", undefined
				filter =
					type: "match"
					# mode can be fulltext, token or wildcard
					mode: data[key+":mode"]
					fields: @getFieldNamesForSearch()
					string: str
					phrase: phrase

			when "field"
				filter =
					type: "in"
					fields: @getFieldNamesForSearch()
					in: [ str ]
		filter

	getHasValueFilter: (data, key=@name()) ->
		if data[key+":has_value"]
			filter =
				type: "in"
				fields: [ @fullName()+".url" ]
				in: [ null ]
				bool: "must_not"
			filter._unnest = true
			filter._has_value_filter = true
			return filter


	showEditPopover: (cdata, element, layout) ->
		form = new CUI.Form
			data: cdata
			fields: @__getEditorFields(cdata)
			onDataChanged: =>
				@__triggerFormChanged(form)
		.start()

		new CUI.Popover
			element: element
			onHide: =>
				@__updateDisplayLink(cdata, layout)
				CUI.Events.trigger
					node: layout
					type: "editor-changed"
			pane:
				header_left: new LocaLabel(loca_key: "custom.data.type.link.edit.modal.title")
				content: form
		.show()

	__getEditorFields: (cdata) ->
		templateSelectField = @__getTemplateSelectFields(cdata)

		fields = []

		if templateSelectField
			fields.push(templateSelectField[0]) # Template selector
			fields.push(templateSelectField[1]) # Placeholder inputs

		hideShow = (field) =>
			data = field.getData()
			if CUI.util.isNull(data.templateIndex)
				field.show()
			else
				field.hide()
		status = @getDataStatus(cdata)
		fallback_url = cdata._template?.url or null # This shows the template value if it exists as placeholder.
		fields.push
			type: CUI.Input
			undo_and_changed_support: false
			form:
				label: $$("custom.data.type.link.modal.form.url.label")
			placeholder: fallback_url or $$("custom.data.type.link.modal.form.url.placeholder")
			name: "url"
			hidden: not CUI.util.isNull(cdata.templateIndex)
			checkInput: (url) => @__isValidUrl(url)
			onDataInit: hideShow

		switch @getTitleType()
			when "text-l10n"
				placeholder = cdata._template?.text or {}
				fields.push
					type: CUI.MultiInput
					name: "text"
					undo_and_changed_support: false
					placeholder: placeholder
					hidden: not CUI.util.isNull(cdata.templateIndex)
					form:
						label: $$("custom.data.type.link.modal.form.text.label")
					control: ez5.loca.getLanguageControl()
					onDataInit: hideShow
			when "text"
				placeholder = cdata._template?.text_plain or ""
				fields.push
					type: CUI.Input
					name: "text_plain"
					placeholder: placeholder
					undo_and_changed_support: false
					hidden: not CUI.util.isNull(cdata.templateIndex)
					form:
						label: $$("custom.data.type.link.modal.form.text.label")
					onDataInit: hideShow

		if @supportsTimestamp()
			fields.push
				type: CUI.DateTime
				name: "datetime"
				undo_and_changed_support: false
				form:
					label: $$("custom.data.type.link.modal.form.datetime.label")

		fields

	__replacePlaceholder: (string, name, value) ->
		return string.replace(///%#{name}%///g, value)

	# Replace all placeholders of the displayname with the current values.
	__fillDisplayName: (data, template) ->
		titleType = @getTitleType()
		if titleType == "none"
			return

		newDisplayname = {}

		for name, value of data.placeholders
			for language, displayname of template.displayname
				if value
					newDisplayname[language] = @__replacePlaceholder(newDisplayname[language] or displayname, name, value)
				else
					newDisplayname[language] = newDisplayname[language] or displayname

		switch titleType
			when "text-l10n"
				if not data.text
					data.text = {}

				for language, displayname of newDisplayname
					data.text[language] = displayname
			when "text"
				data.text_plain = ez5.loca.getBestFrontendValue(newDisplayname)
		return

	# Replace all placeholders of the url with the current values.
	__fillUrl: (data, template) ->
		url = template.url

		for name, value of data.placeholders
			if value
				url = @__replacePlaceholder(url, name, value)
		data.url = url

		return

	__getTemplates: ->
		baseConfig = ez5.session.getBaseConfig("plugin", "custom-data-type-link")
		baseConfig = baseConfig.system or baseConfig # TODO: Remove this after #64076 is merged.
		templates = baseConfig.weblink?.templates
		if not templates or templates.length == 0
			return
		return templates

	#
	# It gets the template and the values in the url for the placeholders.
	#
	# For example, if the template is
	# https://%param1%.programmfabrik/%param2%?q=%param3%
	# and the url is
	# https://www.programmfabrik/demo?q=test
	#
	# then placeholdersValues is
	# {
	#  param1: "www",
	#  param2: "demo",
	#  param3: "test"
	# }
	#
	__getTemplateAndPlaceholdersForUrl: (url) ->
		if not url
			return

		templates = @__getTemplates()
		if not templates
			return

		for template, index in templates
			escapedStringRegExp = CUI.util.escapeRegExp(template.url)
			escapedStringRegExp = escapedStringRegExp.replace(/%[^%]+%/g, "(.*)") # Replace %param% for (.*) to match values.
			urlRegExpValues = new RegExp(escapedStringRegExp)
			match = urlRegExpValues.exec(url)
			if match?.length > 0
				match.shift() # match[0] is the full url, so it is removed.
				placeholdersRegexp = /%([^%]+)%/g
				placeholdersValues = {}
				for value in match
					if value.startsWith("%") and value.endsWith("%")
						continue

					nextPlaceholderMatch = placeholdersRegexp.exec(template.url) # match[0] = %placeholder%, match[1] = placeholder
					if nextPlaceholderMatch and nextPlaceholderMatch[1]
						placeholdersValues[nextPlaceholderMatch[1]] = value
				return {
					template: template
					index: index
					placeholdersValues: placeholdersValues
				}
		return

	__getTemplateSelectFields: (cdata) ->
		templates = @__getTemplates()
		if not templates
			return

		# Get the fields of the placeholders for the template.
		getPlaceholdersFields = (template) =>
			placeholdersFields = []
			for placeholder in template.placeholders
				label = ez5.loca.getBestFrontendValue(placeholder.displayname)
				placeholdersFields.push
					type: CUI.Input
					name: placeholder.key
					form: label: label or placeholder.key
			return placeholdersFields

		# Load the new template by its index in the array, and reload the form.
		loadTemplate = (form, templateIndex) =>
			data = form.getData()
			template = templates[templateIndex]
			templateFound = @__getTemplateAndPlaceholdersForUrl(data.url)
			if templateFound?.template
				for key, value of templateFound.placeholdersValues
					placeholdersData[key] = value

			@__fillUrl(data, template)
			@__fillDisplayName(data, template)

			# Update fields of the placeholders
			placeholdersFields = getPlaceholdersFields(template)
			placeholdersFieldForm.fields = placeholdersFields
			placeholdersFieldForm.hidden = placeholdersFields.length == 0
			placeholdersFieldForm.data = placeholdersData

			form.reload()
			return

		placeholdersData = {}

		# If there is an existing URL, try to match with an existing template and substract the placeholders' values.
		if cdata
			templateFound = @__getTemplateAndPlaceholdersForUrl(cdata.url)
			if templateFound?.template
				placeholdersData = templateFound.placeholdersValues
				cdata.placeholders = placeholdersData
				cdata.templateIndex = templateFound.index

				@__fillData(cdata, templateFound.template)
				placeholdersFields = getPlaceholdersFields(templateFound.template)

		fields = placeholdersFields or []

		placeholdersFieldForm =
			type: CUI.Form
			name: "placeholders"
			fields: fields
			hidden: fields.length == 0
			onDataChanged: (data, field) =>
				mainForm = field.getForm().getForm()
				mainData = mainForm.getData()
				template = templates[mainData.templateIndex]

				@__fillUrl(mainData, template)

				textFieldName = switch @getTitleType()
					when "text-l10n"
						"text"
					when "text"
						"text_plain"

				if textFieldName # It is undefined for 'none' type.
					@__fillDisplayName(mainData, template)
					mainForm.getFieldsByName(textFieldName)[0].reload()

				mainForm.getFieldsByName("url")[0].reload()
				mainForm.getFieldsByName("preview")[0]?.reload()
				return

		templateSelectOptions = [
			text: $$("custom.data.type.link.template.select")
			value: null
		]

		for template, templateIndex in templates
			templateSelectOptions.push(
				text: ez5.loca.getBestFrontendValue(template.name)
				value: templateIndex
			)

		selectField =
			type: CUI.Select
			name: "templateIndex"
			options: templateSelectOptions
			form: label: $$("custom.data.type.link.template.select.label")
			onDataChanged: (data, field) =>
				form = field.getForm()
				if CUI.util.isNull(data.templateIndex)
					placeholdersFieldForm.fields = []
					placeholdersFieldForm.hidden = true
					form.reload()
				else
					loadTemplate(form, data.templateIndex)
				return

		return [selectField, placeholdersFieldForm]

	__fillData: (cdata, template) ->
		@__fillUrl(cdata, template)
		# The displayname is automatic filled if it is empty.
		switch @getTitleType()
			when "text-l10n"
				if CUI.util.isEmpty(cdata.text)
					@__fillDisplayName(cdata, template)
					return

				languages = ez5.session.getConfigFrontendLanguages()
				if not languages.some((language) => not CUI.util.isEmpty(cdata.text[language]))
					@__fillDisplayName(cdata, template)
			when "text"
				if CUI.util.isEmpty(cdata.text_plain)
					@__fillDisplayName(cdata, template)

	renderDetailOutput: (data, top_level_data, opts) ->
		cdata = @initData(data)

		if cdata
			templateFound = @__getTemplateAndPlaceholdersForUrl(cdata.url)
			if templateFound?.template
				cdata.placeholders = templateFound.placeholdersValues
				@__fillData(cdata, templateFound.template)

		@__renderButtonByData(cdata)

	# returns "empty", "ok", "invalid"
	getDataStatus: (cdata) ->
		status = do =>
			if not CUI.isPlainObject(cdata)
				return "empty"

			if CUI.util.isEmpty(cdata.url?.trim())
				return "empty"

			# Check if all placeholders are filled.
			templates = @__getTemplates()
			template = templates?[cdata.templateIndex]
			if template and cdata.placeholders
				placeholders = template.placeholders
				if placeholders.some((placeholder) => CUI.util.isEmpty(cdata.placeholders[placeholder.key]))
					return "invalid"

			if @__isValidUrl(cdata.url)
				return "ok"

			return "invalid"

		return status

	__isValidUrl: (url) ->
		location = CUI.parseLocation(url)
		return !!location and /.+\..{2,}$/.test(location.hostname)

	__renderButtonByData: (cdata, template=false) ->
		if not template
			switch @getDataStatus(cdata)
				when "empty"
					if cdata._template and not CUI.util.isEmpty(cdata._template.url)
						return @__renderButtonByData(cdata._template, true)
					return new CUI.EmptyLabel(text: $$("custom.data.type.link.edit.no_link"))
				when "invalid"
					if CUI.util.isNull(cdata.templateIndex)
						return new CUI.EmptyLabel(text: $$("custom.data.type.link.edit.no_valid_link"), class: "ez-label-invalid")
					else
						return new CUI.EmptyLabel(text: $$("custom.data.type.link.edit.template.missing_placeholders"), class: "ez-label-invalid")

		urlLocation = CUI.parseLocation(cdata.url)
		goto_url = urlLocation.href

		if cdata.datetime
			tt_text = $$("custom.data.type.link.url.tooltip_with_datetime", url: goto_url, datetime: ez5.format_date_and_time(cdata.datetime))
		else
			tt_text = $$("custom.data.type.link.url.tooltip", url: goto_url)

		tooltip_attrs =
			url: goto_url
			datetime: ez5.format_date_and_time(cdata.datetime)

		new CUI.ButtonHref
			appearance: "link"
			href: goto_url
			target: "_blank"
			tooltip:
				markdown: true
				text: tt_text
			text: @getLinkText(cdata) or goto_url
		.DOM

	getLinkText: (cdata) ->
		switch @getTitleType()
			when "none"
				txt = ""
			when "text"
				txt = cdata.text_plain
			when "text-l10n"
				txt = ez5.loca.getBestFrontendValue(cdata.text)

		if not CUI.util.isEmpty(txt)
			txt.trim()
		else
			txt

	getCheckInfo: (mode) ->
		if mode in ["detail", "text"]
			return []

		info = [ $$("custom.data.type.link.valid_url") ]
		info

	checkValue:  (data, top_level_data, opts) ->
		cdata = data[@name()]
		switch @getDataStatus(cdata)
			when "invalid"
				return $$("custom.data.type.link.invalid_url") # The URL provided does not have a valid format.
			when "empty"
				if @isRequired(data, top_level_data, opts)
					return $$("data.column.check.required", field: @fullNameLocalized())
		return true


	getSaveData: (data, save_data, opts = {}) ->
		if opts.demo_data
			return {
				url: "www.example.com"
				text: "Example"
				datetime:
					value: ""
			}

		template_data = data._template?[@name()]
		cdata = data[@name()]

		switch @getDataStatus(cdata)
			when "invalid"
				save_data[@name()] = @__buildData(cdata)
			when "empty"
				if template_data and @getDataStatus(template_data) == "ok"
					save_data[@name()] = template_data
				else
					save_data[@name()] = null
			when "ok"
				save_data[@name()] = @__buildData(cdata)

	__buildData: (cdata) ->
		standard =
			l10ntext: undefined
			text: undefined

		switch @getTitleType()
			when "text-l10n"
				text = cdata.text
				for lang, value of text
					if CUI.util.isEmpty(value.trim())
						continue
					if not standard.l10ntext
						standard.l10ntext = {}
					standard.l10ntext[lang] = value

			when "text"
				text_plain = cdata.text_plain
				if not CUI.util.isEmpty(text_plain?.trim())
					standard.text = text_plain

		url = cdata.url.trim()

		if not standard.text and not standard.l10ntext
			standard.text = url
		else if standard.l10ntext
			delete(standard.text)
		else
			delete(standard.l10ntext)

		location = CUI.parseLocation(url)
		hostnameParts = location?.hostname?.split(".")
		if hostnameParts
			tld = hostnameParts[hostnameParts.length - 1]
		return (
			url: url
			hostname: location?.hostname
			tld: tld or ""
			text: text
			text_plain: text_plain
			datetime: cdata.datetime
			_fulltext:
				l10ntext: text
				text: text_plain
				string: url
			_standard: standard
		)

	hasRenderForSort: ->
		return true

	sortExtraOpts: ->
		return [
			text: $$("custom.data.type.link.modal.form.url.label")
			value: "url"
		]

	getCSVDestinationFields: (csvImporter) ->
		opts =
			csvImporter: csvImporter
			field: @

		[ new CustomDataTypeLinkColumnCSVImporterDestinationField(opts) ]


CustomDataType.register(CustomDataTypeLink)
