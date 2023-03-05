abstract type Citations <: Builder.DocumentPipeline end

Selectors.order(::Type{Citations}) = 3.1  # After cross-references

# TODO
#const asset_dir = normpath(abspath(joinpath(@__DIR__, "..", "citations_assets")))
#const asset_list = [ asset(joinpath("citations_assets","citations.css"),class=:css,islocal=true) ]
#
#function HTMLWriter.plugin_html_assets(::Type{CitationBibliography})::Tuple{String, Vector{HTMLWriter.HTMLAsset}}
#  return asset_dir, QuantumCitations.asset_list
#end

function Selectors.runner(::Type{Citations}, doc::Documents.Document)
    @info "Citations: building citations."
    expand_citations(doc)
end

function expand_citations(doc::Documents.Document)
    # TODO: don't use order in doc.blueprint.pages, but use navigation order
    # instead
    for (src, page) in doc.blueprint.pages
        @info "Expanding citations in $src"
        empty!(page.globals.meta)
        for expanded in values(page.mapping)
            expand_citation(expanded, page, doc)
        end
    end
end

function expand_citation(elem, page, doc)
    Documents.walk(page.globals.meta, elem) do link
        expand_citation(link, page.globals.meta, page, doc)
    end
end

function expand_citation(link::Markdown.Link, meta, page, doc)
    occursin("@cite", link.url) || return false
    if length(link.text) === 1 && isa(link.text[1], String)
        if link.url == "@cite"   # citation format: [key](@cite)
            citation_name = link.text[1]
        else  # citation format:                    [text](@cite key)
            if (m = match(r"^@cite\s*([^\s},]+)\s*$", link.url)) ≢ nothing
                citation_name = m[1]
            else
                error("Invalid citation: [$(link.text)]($(link.url))")
            end
        end
        @info "Expanding citation: $citation_name."

        if haskey(doc.plugins[CitationBibliography].bib, citation_name)
            entry = doc.plugins[CitationBibliography].bib[citation_name]
            headers = doc.internal.headers
            if Anchors.exists(headers, entry.id)
                if Anchors.isunique(headers, entry.id)
                    # Replace the `@cite` url with a path to the referenced header.
                    anchor   = Anchors.anchor(headers, entry.id)
                    path     = relpath(anchor.file, dirname(page.build))
                    authors = xnames(entry) |> tex2unicode
                    if link.url == "@cite"
                        link.text = authors * " (" * xyear(entry) * ")"
                    else
                        # keep original link.text
                    end
                    link.url = string(path, Anchors.fragment(anchor))
                    return true
                else
                    push!(doc.internal.errors, :citations)
                    @warn "'$(entry.id)' is not unique in $(Utilities.locrepr(page.source))."
                end
            else
                push!(doc.internal.errors, :citations)
                @warn "reference for '$(entry.id)' could not be found in $(Utilities.locrepr(page.source))."
            end
        else
            error("Citation not found in bibliography: $(citation_name)")
        end
    else
        error("Invalid citation: $(link.text)")
    end
    return false
end

expand_citation(other, meta, page, doc) = true # Continue to `walk` through element `other`.
