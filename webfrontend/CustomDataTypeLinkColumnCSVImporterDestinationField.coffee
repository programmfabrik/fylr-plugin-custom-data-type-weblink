class CustomDataTypeLinkColumnCSVImporterDestinationField extends ObjecttypeCSVImporterDestinationField

	@wikipediaLinkRegex: /\[\[(?!.+?:)([^\|\]\[]+)\|([^\|\]\[]+)\]\]|\[\[([^\|\]\[]+)\]\]/

	initOpts: ->
		super()
		@mergeOpt "field",
			check: CustomDataTypeLink

	supportsHierarchy: ->
		false

	formatValues: (values) ->
		data = []
		for value in values
			try
				data.push(JSON.parse(value))
			catch
				if CUI.isString(value)
					cdata = url: value

					if groups = CustomDataTypeLinkColumnCSVImporterDestinationField.wikipediaLinkRegex.exec(value)
						if groups[3] # Only url. [[www.url.com]]
							cdata = url: groups[3]
						else # Url and text. [[www.url.com|text]]
							cdata = url: groups[1]
							content = groups[2]

							switch @_field.getTitleType()
								when "text-l10n"
									language = ez5.loca.getLanguage()
									cdata.text = {}
									cdata.text[language] = content
								when "text"
									cdata.text_plain = content

					if CUI.parseLocation(cdata.url) # Check if URL is valid.
						data.push(@_field.__buildData(cdata))

		if data.length == 0
			return undefined
		else if data.length == 1
			return data[0]
		else
			return data