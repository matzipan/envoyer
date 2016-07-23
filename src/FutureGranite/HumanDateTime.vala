/*
 * Copyright 2016 Andrei-Costin Zisu
 *
 * This software is licensed under the GNU Lesser General Public License
 * (version 2.1 or later).  See the COPYING file in this distribution.
 */
 
public class Envoyer.FutureGranite.HumanDateTime : GLib.Object {
    private GLib.DateTime moment;

    public HumanDateTime (GLib.DateTime moment) {
    	assert(moment != null);
    	
    	this.moment = moment.to_utc();
    }
    
    public string compared_to_now (bool fallback_to_datetime = true) {
        var now = new GLib.DateTime.now_utc ();
        var timestamp = moment.to_unix ();
        var comparison_timestamp = now.to_utc ().to_unix ();
        
        if ((comparison_timestamp - timestamp).abs() < 20) {
            return "just now";
        }
        
        if (fallback_to_datetime && fallback_to_datetime_satisified (timestamp, comparison_timestamp)) {
            return fallback (moment, now);
        }
        
        var difference = difference_to_datetime (moment, now);


        if(comparison_timestamp - timestamp < 0) {
            return "%s from now".printf(difference);
        } else {
            return "%s ago".printf(difference);
        }
    }
    
    public string compared_to_datetime (GLib.DateTime comparison_moment, bool fallback_to_datetime = true) {
        var timestamp = moment.to_unix ();
        var comparison_timestamp = comparison_moment.to_utc ().to_unix ();
        
        if (
            comparison_timestamp == timestamp ||  
            (
                fallback_to_datetime && 
                fallback_to_datetime_satisified (timestamp, comparison_timestamp)
            )
           ) {
            return fallback (moment, comparison_moment.to_utc ());
        }
        
        var difference = difference_to_datetime (moment, comparison_moment);

        if(comparison_timestamp - timestamp < 0) {
            return "%s after".printf(difference);
        } else {
            return "%s before".printf(difference);
        }
    }
    
    public string difference_to_datetime (GLib.DateTime moment, GLib.DateTime comparison_moment) {;
        GLib.TimeSpan difference;
        if(moment.compare(comparison_moment) >= 0) {
            difference = moment.difference(comparison_moment);
        } else {
            difference = comparison_moment.difference(moment);
        }
        
        var days = (int) (difference / GLib.TimeSpan.DAY);
        var hours = (int) (difference / GLib.TimeSpan.HOUR);
        var minutes = (int) (difference / GLib.TimeSpan.MINUTE);
        var seconds = (int) (difference / GLib.TimeSpan.SECOND);
        
        if(days == 1) {
            return "1 day";
        }
        
        if(days > 1) {
            return "%d days".printf(days);
        }
        
        if(hours == 1) {
            return "1 hour";
        }
        
        if(hours > 1) {
            return "%d hours".printf(hours);
        }
        
        if(minutes == 1) {
            return "1 minute";
        }
        
        if(minutes > 1) {
            return "%d minutes".printf(minutes);
        }
        
        if(seconds == 1) {
            return "1 second";
        }

        return "%d seconds".printf(seconds);
    }
    
    public bool fallback_to_datetime_satisified (int64 timestamp, int64 comparison_timestamp) {
        return (timestamp-comparison_timestamp).abs() > 4 * 60 * 60;
    }
    
    public string fallback (GLib.DateTime moment, GLib.DateTime comparison_moment) {
        var timestamp = moment.to_unix ();
        var comparison_timestamp = comparison_moment.to_unix ();
        
        var show_year = (comparison_timestamp - timestamp).abs() > 365*24*60*60;
        
        return moment.format (Granite.DateTime.get_default_date_format(false, true, show_year));
    
    }
}
