# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
#
#   Widget: Label.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export WidgetLabel, change_text

################################################################################
#                                     Type
################################################################################

@with_kw mutable struct WidgetLabel{T<:WidgetParent} <: Widget

    # API
    # ==========================================================================
    common::WidgetCommon{T}

    # Parameters related to the widget
    # ==========================================================================
    color::Int
    text::AbstractString
end

################################################################################
#                                     API
################################################################################

# Labels cannot accept focus.
accept_focus(widget::WidgetLabel) = false

function create_widget(::Type{Val{:label}}, parent::WidgetParent;
                       alignment = :l,
                       color::Int = 0,
                       text::AbstractString = "Text",
                       kwargs...)

    # Positioning configuration.
    posconf = wpc(;kwargs...)

    # Initial processing of the position.
    _process_vertical_info!(posconf)
    _process_horizontal_info!(posconf)

    # Check if all positioning is defined and, if not, try to help by
    # automatically defining the height and/or width.
    posconf.vertical   == :unknown && (posconf.height = 1)
    posconf.horizontal == :unknown && (posconf.width = length(text))

    # Create the common parameters of the widget.
    common = create_widget_common(parent, posconf)

    # Create the widget.
    widget = WidgetLabel(common = common, text   = "", color  = color)

    # Update the text.
    change_text(widget, text; alignment = alignment)

    # Add the new widget to the parent widget list.
    add_widget(parent, widget)

    @log info "create_widget" """
    A label was created in $(obj_desc(parent)).
        Size        = ($(common.height), $(common.width))
        Coordinate  = ($(common.top), $(common.left))
        Positioning = ($(common.posconf.vertical),$(common.posconf.horizontal))
        Text        = \"$text\"
        Reference   = $(obj_to_ptr(widget))"""

    # Return the created widget.
    return widget
end

function redraw(widget::WidgetLabel)
    @unpack common, color, text = widget
    @unpack buffer = common

    wclear(buffer)
    color > 0 && wattron(buffer, color)
    mvwprintw(buffer, 0, 0, widget.text)
    color > 0 && wattroff(buffer, color)
    return nothing
end

################################################################################
#                           Custom widget functions
################################################################################

"""
    function change_text(widget::WidgetLabel, new_text::AbstractString; alignment = :l, color::Int = -1)

Change to text of the label widget `widget` to `new_text`.

The text alignment in the widget can be selected by the keyword `alignment`,
which can be:

* `:l`: left alignment (**default**);
* `:c`: Center alignment; or
* `:r`: Right alignment.

The text color can be selected by the keyword `color`. It it is negative
(**default**), then the current color will not be changed.

"""
function change_text(widget::WidgetLabel, new_text::AbstractString;
                     alignment = :l, color::Int = -1)

    @unpack parent, buffer, width = widget.common

    # Split the string in each line.
    tokens = split(new_text, "\n")

    # Formatted text.
    text = ""

    for line in tokens
        # Check the alignment and print accordingly.
        if alignment == :r
            col   = width - length(line) - 1
            text *= " "^col * line * "\n"
        elseif alignment == :c
            col   = div(width - length(line), 2)
            text *= " "^col * line * "\n"
        else
            text *= line * "\n"
        end
    end

    widget.text = text

    # Set the color.
    color >= 0 && (widget.color = color)

    @log verbose "change_text" "$(obj_desc(widget)): Label text changed to \"$new_text\"."

    request_update(widget)

    return nothing
end
