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
 
void add_compared_to_now_tests () {
    Test.add_func ("/compared_to_now/now", () => {
        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (new GLib.DateTime.now_utc ());

        assert(human_datetime.compared_to_now () == "just now");
    });


    Test.add_func ("/compared_to_now/5-minutes-ago", () => {
        var now = new GLib.DateTime.now_utc ();

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_minutes(-5));

        assert(human_datetime.compared_to_now () == "5 minutes ago");
    });

    Test.add_func ("/compared_to_now/5-minutes-from-now", () => {
        var now = new GLib.DateTime.now_utc ();

        // hours is 6 since it takes some time until compared_to_now creates the time instance
        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_minutes(6));

        assert(human_datetime.compared_to_now () == "5 minutes from now");
    });

    Test.add_func ("/compared_to_now/3-hours-from-now", () => {
        var now = new GLib.DateTime.now_utc ();

        // hours is 4 since it takes some time until compared_to_now creates the time instance
        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_hours(4));

        assert(human_datetime.compared_to_now () == "3 hours from now");
    });

    Test.add_func ("/compared_to_now/3-hours-ago", () => {
        var now = new GLib.DateTime.now_utc ();

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_hours(-3));

        assert(human_datetime.compared_to_now () == "3 hours ago");
    });

    Test.add_func ("/compared_to_now/3-hours-and-30-minutes-ago", () => {
        var now = new GLib.DateTime.now_utc ();

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_hours(-3).add_minutes(-30));

        assert(human_datetime.compared_to_now () == "3 hours ago");
    });
}

void add_compare_to_datetime_tests () {
    Test.add_func ("/compared_to_datetime/5-minutes-before", () => {
        var now = new GLib.DateTime.now_utc ();

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_minutes(-5));

        assert(human_datetime.compared_to_datetime (now) == "5 minutes before");
    });

    Test.add_func ("/compared_to_datetime/5-minutes-after", () => {
        var now = new GLib.DateTime.now_utc ();

        // hours is 6 since it takes some time until compared_to_now creates the time instance
        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_minutes(5));

        assert(human_datetime.compared_to_datetime (now) == "5 minutes after");
    });

    Test.add_func ("/compared_to_datetime/3-hours-after", () => {
        var now = new GLib.DateTime.now_utc ();

        // hours is 4 since it takes some time until compared_to_now creates the time instance
        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_hours(3));

        assert(human_datetime.compared_to_datetime (now) == "3 hours after");
    });

    Test.add_func ("/compared_to_datetime/3-hours-before", () => {
        var now = new GLib.DateTime.now_utc ();

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_hours(-3));

        assert(human_datetime.compared_to_datetime (now) == "3 hours before");
    });

    Test.add_func ("/compared_to_datetime/3-hours-and-30-minutes-before", () => {
        var now = new GLib.DateTime.now_utc ();

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now.add_hours(-3).add_minutes(-30));

        assert(human_datetime.compared_to_datetime (now) == "3 hours before");
    });

    Test.add_func ("/compared_to_datetime/fallback-year", () => {
        var now = new GLib.DateTime.now_utc ();
        var moment = now.add_years(-1).add_minutes(-30);

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (moment);

        // Unit under test uses Granite to determine which format it should use, so testing may fail under different locales
        assert(human_datetime.compared_to_datetime (now) == moment.format("%e %B %Y"));
    });

    Test.add_func ("/compared_to_datetime/fallback", () => {
        var now = new GLib.DateTime.now_utc ();
        var moment = now.add_days(-5);

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (moment);

        // Unit under test uses Granite to determine which format it should use, so testing may fail under different locales
        assert(human_datetime.compared_to_datetime (now) == moment.format("%e %B"));
    });

    Test.add_func ("/compared_to_datetime/now", () => {
        var now = new GLib.DateTime.now_utc ();

        var human_datetime = new Envoyer.FutureGranite.HumanDateTime (now);

        // Unit under test uses Granite to determine which format it should use, so testing may fail under different locales
        assert(human_datetime.compared_to_datetime (now) == now.format("%e %B"));
    });
}

void main (string[] args) {
    Test.init (ref args);
    add_compared_to_now_tests ();
    add_compare_to_datetime_tests ();
    Test.run ();
}
