# CountrySelect
module ActionView
  module Helpers
    module FormOptionsHelper
      silence_warnings do
        COUNTRIES = [
          [_('Andorra'), 'AD'],
          [_('Afghanistan'), 'AF'],
          [_('Aland Islands'), 'AX'],
          [_('Albania'), 'AL'],
          [_('Algeria'), 'DZ'],
          [_('American Samoa'), 'AS'],
          [_('Angola'), 'AO'],
          [_('Anguilla'), 'AI'],
          [_('Antarctica'), 'AQ'],
          [_('Antigua and Barbuda'), 'AG'],
          [_('Argentina'), 'AR'],
          [_('Armenia'), 'AM'],
          [_('Aruba'), 'AW'],
          [_('Australia'), 'AU'],
          [_('Austria'), 'AT'],
          [_('Azerbaijan'), 'AZ'],
          [_('Bahamas'), 'BS'],
          [_('Bahrain'), 'BH'],
          [_('Bangladesh'), 'BD'],
          [_('Barbados'), 'BB'],
          [_('Belarus'), 'BY'],
          [_('Belgium'), 'BE'],
          [_('Belize'), 'BZ'],
          [_('Benin'), 'BJ'],
          [_('Bermuda'), 'BM'],
          [_('Bhutan'), 'BT'],
          [_('Bolivia'), 'BO'],
          [_('Bosnia and Herzegovina'), 'BA'],
          [_('Botswana'), 'BW'],
          [_('Bouvet Island'), 'BV'],
          [_('Brazil'), 'BR'],
          [_('British Antarctic Territory'), 'BQ'],
          [_('British Indian Ocean Territory'), 'IO'],
          [_('British Virgin Islands'), 'VG'],
          [_('Brunei'), 'BN'],
          [_('Bulgaria'), 'BG'],
          [_('Burkina Faso'), 'BF'],
          [_('Burundi'), 'BI'],
          [_('Cambodia'), 'KH'],
          [_('Cameroon'), 'CM'],
          [_('Canada'), 'CA'],
          [_('Canton and Enderbury Islands'), 'CT'],
          [_('Cape Verde'), 'CV'],
          [_('Cayman Islands'), 'KY'],
          [_('Central African Republic'), 'CF'],
          [_('Chad'), 'TD'],
          [_('Chile'), 'CL'],
          [_('China'), 'CN'],
          [_('Christmas Island'), 'CX'],
          [_('Cocos Islands'), 'CC'],
          [_('Colombia'), 'CO'],
          [_('Comoros'), 'KM'],
          [_('Congo - Brazzaville'), 'CG'],
          [_('Congo - Kinshasa'), 'CD'],
          [_('Cook Islands'), 'CK'],
          [_('Costa Rica'), 'CR'],
          [_('Croatia'), 'HR'],
          [_('Cuba'), 'CU'],
          [_('Cyprus'), 'CY'],
          [_('Czech Republic'), 'CZ'],
          [_('Denmark'), 'DK'],
          [_('Djibouti'), 'DJ'],
          [_('Dominica'), 'DM'],
          [_('Dominican Republic'), 'DO'],
          [_('Dronning Maud Land'), 'NQ'],
          [_('East Timor'), 'TL'],
          [_('Ecuador'), 'EC'],
          [_('Egypt'), 'EG'],
          [_('El Salvador'), 'SV'],
          [_('Equatorial Guinea'), 'GQ'],
          [_('Eritrea'), 'ER'],
          [_('Estonia'), 'EE'],
          [_('Ethiopia'), 'ET'],
          [_('European Union'), 'EU'],
          [_('European Union'), 'QU'],
          [_('Falkland Islands'), 'FK'],
          [_('Faroe Islands'), 'FO'],
          [_('Fiji'), 'FJ'],
          [_('Finland'), 'FI'],
          [_('France'), 'FR'],
          [_('French Guiana'), 'GF'],
          [_('French Polynesia'), 'PF'],
          [_('French Southern and Antarctic Territories'), 'FQ'],
          [_('French Southern Territories'), 'TF'],
          [_('Gabon'), 'GA'],
          [_('Gambia'), 'GM'],
          [_('Georgia'), 'GE'],
          [_('Germany'), 'DE'],
          [_('Ghana'), 'GH'],
          [_('Gibraltar'), 'GI'],
          [_('Greece'), 'GR'],
          [_('Greenland'), 'GL'],
          [_('Grenada'), 'GD'],
          [_('Guadeloupe'), 'GP'],
          [_('Guam'), 'GU'],
          [_('Guatemala'), 'GT'],
          [_('Guernsey'), 'GG'],
          [_('Guinea'), 'GN'],
          [_('Guinea-Bissau'), 'GW'],
          [_('Guyana'), 'GY'],
          [_('Haiti'), 'HT'],
          [_('Heard Island and McDonald Islands'), 'HM'],
          [_('Honduras'), 'HN'],
          [_('Hong Kong'), 'HK'],
          [_('Hong Kong SAR China'), 'HK'],
          [_('Hungary'), 'HU'],
          [_('Iceland'), 'IS'],
          [_('India'), 'IN'],
          [_('Indonesia'), 'ID'],
          [_('Iran'), 'IR'],
          [_('Iraq'), 'IQ'],
          [_('Ireland'), 'IE'],
          [_('Isle of Man'), 'IM'],
          [_('Israel'), 'IL'],
          [_('Italy'), 'IT'],
          [_('Ivory Coast'), 'CI'],
          [_('Jamaica'), 'JM'],
          [_('Japan'), 'JP'],
          [_('Jersey'), 'JE'],
          [_('Johnston Island'), 'JT'],
          [_('Jordan'), 'JO'],
          [_('Kazakhstan'), 'KZ'],
          [_('Kenya'), 'KE'],
          [_('Kiribati'), 'KI'],
          [_('Kuwait'), 'KW'],
          [_('Kyrgyzstan'), 'KG'],
          [_('Laos'), 'LA'],
          [_('Latvia'), 'LV'],
          [_('Lebanon'), 'LB'],
          [_('Lesotho'), 'LS'],
          [_('Liberia'), 'LR'],
          [_('Libya'), 'LY'],
          [_('Liechtenstein'), 'LI'],
          [_('Lithuania'), 'LT'],
          [_('Luxembourg'), 'LU'],
          [_('Macau'), 'MO'],
          [_('Macau SAR China'), 'MO'],
          [_('Macedonia'), 'MK'],
          [_('Madagascar'), 'MG'],
          [_('Malawi'), 'MW'],
          [_('Malaysia'), 'MY'],
          [_('Maldives'), 'MV'],
          [_('Mali'), 'ML'],
          [_('Malta'), 'MT'],
          [_('Marshall Islands'), 'MH'],
          [_('Martinique'), 'MQ'],
          [_('Mauritania'), 'MR'],
          [_('Mauritius'), 'MU'],
          [_('Mayotte'), 'YT'],
          [_('Mexico'), 'MX'],
          [_('Micronesia'), 'FM'],
          [_('Midway Islands'), 'MI'],
          [_('Moldova'), 'MD'],
          [_('Monaco'), 'MC'],
          [_('Mongolia'), 'MN'],
          [_('Montenegro'), 'ME'],
          [_('Montserrat'), 'MS'],
          [_('Morocco'), 'MA'],
          [_('Mozambique'), 'MZ'],
          [_('Myanmar'), 'MM'],
          [_('Namibia'), 'NA'],
          [_('Nauru'), 'NR'],
          [_('Nepal'), 'NP'],
          [_('Netherlands'), 'NL'],
          [_('Netherlands Antilles'), 'AN'],
          [_('Neutral Zone'), 'NT'],
          [_('New Caledonia'), 'NC'],
          [_('New Zealand'), 'NZ'],
          [_('Nicaragua'), 'NI'],
          [_('Niger'), 'NE'],
          [_('Nigeria'), 'NG'],
          [_('Niue'), 'NU'],
          [_('Norfolk Island'), 'NF'],
          [_('North Korea'), 'KP'],
          [_('North Vietnam'), 'VD'],
          [_('Northern Mariana Islands'), 'MP'],
          [_('Norway'), 'NO'],
          [_('Oman'), 'OM'],
          [_('Outlying Oceania'), 'QO'],  #Unicode CLDR http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#User-assigned_code_elements
          [_('Pacific Islands Trust Territory'), 'PC'],
          [_('Pakistan'), 'PK'],
          [_('Palau'), 'PW'],
          [_('Palestinian Territory'), 'PS'],
          [_('Panama'), 'PA'],
          [_('Panama Canal Zone'), 'PZ'],
          [_('Papua New Guinea'), 'PG'],
          [_('Paraguay'), 'PY'],
          [_('People\'s Democratic Republic of Yemen'), 'YD'],
          [_('Peru'), 'PE'],
          [_('Philippines'), 'PH'],
          [_('Pitcairn'), 'PN'],
          [_('Poland'), 'PL'],
          [_('Portugal'), 'PT'],
          [_('Puerto Rico'), 'PR'],
          [_('Qatar'), 'QA'],
          [_('Reunion'), 'RE'],
          [_('Romania'), 'RO'],
          [_('Russia'), 'RU'],
          [_('Rwanda'), 'RW'],
          [_('Saint Barthélemy'), 'BL'],
          [_('Saint Helena'), 'SH'],
          [_('Saint Kitts and Nevis'), 'KN'],
          [_('Saint Lucia'), 'LC'],
          [_('Saint Martin'), 'MF'],
          [_('Saint Pierre and Miquelon'), 'PM'],
          [_('Saint Vincent and the Grenadines'), 'VC'],
          [_('Samoa'), 'WS'],
          [_('San Marino'), 'SM'],
          [_('Sao Tome and Principe'), 'ST'],
          [_('Saudi Arabia'), 'SA'],
          [_('Senegal'), 'SN'],
          [_('Serbia'), 'RS'],
          [_('Serbia and Montenegro'), 'CS'],
          [_('Seychelles'), 'SC'],
          [_('Sierra Leone'), 'SL'],
          [_('Singapore'), 'SG'],
          [_('Slovakia'), 'SK'],
          [_('Slovenia'), 'SI'],
          [_('Solomon Islands'), 'SB'],
          [_('Somalia'), 'SO'],
          [_('South Africa'), 'ZA'],
          [_('South Georgia and the South Sandwich Islands'), 'GS'],
          [_('South Korea'), 'KR'],
          [_('Spain'), 'ES'],
          [_('Sri Lanka'), 'LK'],
          [_('Sudan'), 'SD'],
          [_('Suriname'), 'SR'],
          [_('Svalbard and Jan Mayen'), 'SJ'],
          [_('Swaziland'), 'SZ'],
          [_('Sweden'), 'SE'],
          [_('Switzerland'), 'CH'],
          [_('Syria'), 'SY'],
          [_('Taiwan'), 'TW'],
          [_('Tajikistan'), 'TJ'],
          [_('Tanzania'), 'TZ'],
          [_('Thailand'), 'TH'],
          [_('Togo'), 'TG'],
          [_('Tokelau'), 'TK'],
          [_('Tonga'), 'TO'],
          [_('Trinidad and Tobago'), 'TT'],
          [_('Tunisia'), 'TN'],
          [_('Turkey'), 'TR'],
          [_('Turkmenistan'), 'TM'],
          [_('Turks and Caicos Islands'), 'TC'],
          [_('Tuvalu'), 'TV'],
          [_('U.S. Miscellaneous Pacific Islands'), 'PU'],
          [_('U.S. Virgin Islands'), 'VI'],
          [_('Uganda'), 'UG'],
          [_('Ukraine'), 'UA'],
          [_('Union of Soviet Socialist Republics'), 'SU'],
          [_('United Arab Emirates'), 'AE'],
          [_('United Kingdom'), 'GB'],
          [_('United States'), 'US'],
          [_('United States Minor Outlying Islands'), 'UM'],
          [_('Uruguay'), 'UY'],
          [_('Uzbekistan'), 'UZ'],
          [_('Vanuatu'), 'VU'],
          [_('Vatican'), 'VA'],
          [_('Venezuela'), 'VE'],
          [_('Vietnam'), 'VN'],
          [_('Wake Island'), 'WK'],
          [_('Wallis and Futuna'), 'WF'],
          [_('Western Sahara'), 'EH'],
          [_('Yemen'), 'YE'],
          [_('Zambia'), 'ZM'],
          [_('Zimbabwe'), 'ZW'],
          [_("Unknown or Invalid Region"), "ZZ"]
        ]
      end
    end
  end
end