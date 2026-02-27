# SQL-Functions
Useful SQL functions you can add to your code to make it easier. They're mostly in postgreSQL but you can translate them into any SQL Version easily

1. get_state_abbreviation:  Returns a state abbreviation given a state (US Only)
2. normalize_name:          Helps you compare names. an alternative to the similarity function but cosuming a lot less recources. As long as both strings have the same words
                            Function normalize_name transform a name into an order string. in order to work, evaluated names have to have no commas. Ex:
                          
                          				call ebg_qa.normalize_name('Ana B Teran');
                          				call ebg_qa.normalize_name('Teran Ana B');
                          				call ebg_qa.normalize_name('B Teran Ana);
                          		
                          				All of these calls will return 'Ana B Teran'
3. normalize_address: This function helps create a normalize address version focusing on the street elements only for comparison purposes. Works with US only addresses
