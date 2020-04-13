/*
 * Copyright (C) 2020  Andrei-Costin Zisu
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
 
public class Envoyer.Util.Range {
  public Range (uint64 location, uint64 length) {
      this.location = location;
      this.length = length;
  }

  public uint64 location;

  /*
   * We're using the Mailcore convention. Length 0 means that there is 1
   * element in the range, the one corresponding to the location value. Length
   * 1 means that there are two elements, the one corresponding to location
   * value and the one corresponding to location + 1.
   */
  public uint64 length;

  public bool contains (uint64 value) {
    return location <= value && value <= location + length;
  }
}