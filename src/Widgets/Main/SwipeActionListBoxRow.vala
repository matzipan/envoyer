/*
 * Copyright (C) 2019  Andrei-Costin Zisu
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

 using Envoyer.Models;

/*
 * Some references for inspiration:
 * - https://gitlab.gnome.org/exalm/gestures-playground/-/tree/titlebar
 * - https://gitlab.gnome.org/exalm/gestures-playground/-/tree/master
 */
 public class Envoyer.Widgets.Main.SwipeActionListBoxRow : Gtk.ListBoxRow {
    private Gtk.EventBox event_box;
    private Gdk.Pixbuf swipe_left_icon_pixbuf;
    
    // Configuration parameters
    // Icons are square, so we only have one dimension
    private const int icon_size = 36;
    // The maximum vertical scroll for the swipe
    private const double maximum_x = 50;
    // Overshoot friction for when swiping right
    private const double overshoot_friction = 8;
    // This is the swipe progress threshold above which the action is triggered
    private const double trigger_threshold = 0.7;
    // Animation timer interval
    private const uint animation_interval = 10;
    // Animation increment at each interval
    private const double animation_increment = 10;
    // Swipe detection x threshold. Accumulated x should be greater than this value
    private const double swipe_detection_x_threshold = 1;
    // Swipe detection y threshold. Accumulated y should be lower than this value
    private const double swipe_detection_y_threshold = 1;

    public signal void action_triggered ();

    private Gtk.StyleContext _icon_style;

    private Gtk.StyleContext icon_style {
        get {
            if (_icon_style != null) {
                return _icon_style;
            }
    
            _icon_style = get_icon_style_context_for_object ("envoyer-swipe-action-icon");
                    
            return _icon_style;
        }
    }

    private Gtk.StyleContext _swipe_box_style;

    private Gtk.StyleContext swipe_box_style {
        get {
            if (_swipe_box_style != null) {
                return _swipe_box_style;
            }
    
            _swipe_box_style = get_icon_style_context_for_object ("envoyer-swipe-box");
    
            return _swipe_box_style;
        }
    }

    construct {
        build_ui ();
        connect_signals ();
    }

    private void build_ui () {
        event_box = new Gtk.EventBox ();
        base.add(event_box);
    }

    private Gtk.StyleContext get_icon_style_context_for_object (string class_string) {
        var style_path = get_path ();
        style_path.append_type (typeof (Gtk.Widget));
    
        var icon_style_context = new Gtk.StyleContext ();
        icon_style_context.set_path (style_path);
        icon_style_context.add_class (class_string);

        return icon_style_context;
    }

    private void connect_signals () {
        event_box.set_events (Gdk.EventMask.SMOOTH_SCROLL_MASK);
        event_box.scroll_event.connect (scroll_handler);
    }


    private void state_update (bool was_swipe_previously_active, double last_progress_value) {
        if (swipe_progress > trigger_threshold) {
            if (swipe_active_now) {
                if (!icon_move_animation_running) {
                    start_icon_move_animation (false);
                }
            }
        } else {
            if (icon_moved_to_trigger_area && !icon_move_animation_running) {
                start_icon_move_animation (true);
            }

            if (last_progress_value > trigger_threshold && !swipe_active_now && was_swipe_previously_active) {
                //@TODO Add animation for swipe out in case swipe progress is < 100%

                action_triggered ();
            }
        }

        if (swipe_active_now && !was_swipe_previously_active) {
            // Fresh start, fresh state
            animation_translation = 0;
            icon_move_animation_running = false;
            icon_moved_to_trigger_area = false;
        }

        queue_draw();
    }

    private bool icon_moved_to_trigger_area = false;
    private bool icon_move_animation_running = false;
    private double animation_translation;
    private bool move_back = false;

    private void start_icon_move_animation (bool move_back) {
        this.move_back = move_back;
        if (move_back) {
            icon_moved_to_trigger_area = false;
            // Start translation from the maximum value
            animation_translation = swipe_translation;
        } else {
            // Start translation from the minimum value
            animation_translation = 0;
        }
        GLib.Timeout.add (animation_interval, icon_move_animation_timer);
        icon_move_animation_running = true;
    }

    private bool scroll_active_now = false;
    private bool swipe_active_now = false;

    private double accumulated_x = 0;
    private double accumulated_y = 0;

    private bool scroll_handler (Gdk.EventScroll event) {
        if (event.scroll.direction == Gdk.ScrollDirection.SMOOTH) {
            var was_scroll_previously_active = scroll_active_now;
            scroll_active_now = event.scroll.is_stop != 1;

            var was_swipe_previously_active = swipe_active_now;

            var last_progress_value = swipe_progress;

            if((! was_scroll_previously_active && scroll_active_now) || !scroll_active_now) {
                // We just started scrolling or we just stopped scrolling
                accumulated_x = 0;
                accumulated_y = 0;
                swipe_active_now = false;
            } 
            
            if(scroll_active_now) {
                accumulated_y += event.scroll.delta_y;
                accumulated_x += event.scroll.delta_x;

                // With this x and y thresholds we avoid accidentally triggering a swipe when scrolling vertically
                if ((accumulated_x.abs () > swipe_detection_x_threshold && accumulated_y.abs () <= swipe_detection_y_threshold)
                    || swipe_active_now) {
                    swipe_active_now = true;
                }
            }
            
            state_update (was_swipe_previously_active, last_progress_value);

            // We don't propagate the scroll if we detected the swipe
            if(swipe_active_now) {
                return Gdk.EVENT_STOP;
            }
        }

        return Gdk.EVENT_PROPAGATE;
    }

    public void set_swipe_icon_name (string swipe_left_icon_name) {
        var icon_theme = Gtk.IconTheme.get_default ();

        var icon_info = icon_theme.lookup_icon (swipe_left_icon_name, icon_size, Gtk.IconLookupFlags.GENERIC_FALLBACK);
        swipe_left_icon_pixbuf = icon_info.load_symbolic (icon_style.get_color (get_state_flags ()));

        //@TODO handle cases where icon is not found
    }

    public void add (Gtk.Widget widget) {
        event_box.add (widget);
    }

    private double swipe_progress {
        get {
            if (!swipe_active_now) {
                return 0;
            }
            
            return (accumulated_x / maximum_x);
        }
    }

    private double swipe_translation {
        get {
            if (swipe_progress < 0) {
                return - Math.log10 (1 + swipe_progress.abs () / overshoot_friction) * get_allocated_width ();
            } else {
                return swipe_progress * get_allocated_width ();

            }
        }
    }

    private bool icon_move_animation_timer () {
        // This function could be made a bit more generic but it'll do for now
        if (move_back) {
            animation_translation -= animation_increment; 
            if (animation_translation <= 0) {
                // Clamp the value
                animation_translation = 0;

                icon_moved_to_trigger_area = false;
                icon_move_animation_running = false;
                return false;
            }
        } else {
            animation_translation += animation_increment; 
            if (animation_translation >= swipe_translation) {
                // Clamp the value
                animation_translation = swipe_translation;

                icon_moved_to_trigger_area = true;
                icon_move_animation_running = false;
                return false;
            }
        }

        queue_draw ();

        return true;
    }

    private double swipe_right_icon_horizontal_position {
        get {
            var width = get_allocated_width ();
            if (swipe_translation < icon_size) {
                return width;
            } else {
                double return_value;
                if (icon_moved_to_trigger_area) {
                    return_value = width;
                } else {
                    return_value = width + swipe_translation  - double.max(animation_translation, icon_size);
                }
                
                // Clamp to the visible box of the listboxrow
                return double.max(swipe_translation, return_value);
            } 
        }
    }

    private void draw_right_box (Cairo.Context cr) {
        var width = get_allocated_width ();
		var height = get_allocated_height ();

        // Draw swipe box
        swipe_box_style.render_background (cr, width, 0, swipe_translation, height);
        cr.fill ();

        // Draw delete icon
        double swipe_right_icon_vertical_position = (height - icon_size) / 2;

        icon_style.render_icon (cr, swipe_left_icon_pixbuf, swipe_right_icon_horizontal_position,swipe_right_icon_vertical_position );
        cr.paint ();
        cr.fill ();
    }

    public override bool draw (Cairo.Context cr) {
        cr.translate (-swipe_translation, 0);

        base.draw (cr);
        
        draw_right_box (cr);
        
        return true;      
    }
 }