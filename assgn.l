%{
/*
Submitted by - Ekamjit Singh 
Roll Number  - 2019CSC1001
*/

#include <iostream>
#include <string>
#include <stdio.h>
#include "sqlite3.h"    //connecting the sqlite3 database
#include "assgn.tab.h"      // the output of bison on example0 .y

/*Function prototypes*/
    void yyerror(char*);    //Prompts parsing error.
    int yyparse(void);      //Returns 0 if the input it parses is valid according  
                            //to the given grammar rules, otherwise returns 1

    //callback functions used with sqlite3_exe function to execute SQL query and return its output                     
    int callbackformula(void *NotUsed, int argc, char **argv, char **azColName);   
    int callbackfields(void *NotUsed, int argc, char **argv, char **azColName);
    int callback(void *NotUsed, int argc, char **argv, char **azColName);


using namespace std;

string formula;         //Stores formula read from formula table
string fields[30];      //String Array. Stores all field values from formulafields table
int k=0;                //No of fields

%}

%%

[ \t\n]+	            ;

"<A"[1-9][0-9]*">"	    { return VARIABLE;}

[0-9]+ 		            { return NUMBER;}

[0-9]+\.[0-9]+ 	        { return NUMBER;}

[a-z]*[A-Z]*[a-z]* 	    { return CHARSET;}

"="		                { return EQUALS;}		

[+ \- / *]              { return OPR;}

"("		                { return LBR;}
")"		                { return RBR;}
";"		                { return SEMICOLON;}
.		                { printf(" \n Unrecognized symbol %s\n Could not Parse!\n", yytext); exit(0);}

%%


void yyerror(std::string str){ printf (" ERROR : Could not parse !\n" );}
int yywrap(void){ }


int callback(void *NotUsed, int argc, char **argv, char **azColName){

    for(int i = 0; i < argc; i++)
    {
        cout<<azColName[i]<<": "<<argv[i]<<endl;    //used to print final result
       
    }
     cout<<endl;
    return 0;
}

int callbackformula(void *NotUsed, int argc, char **argv, char **azColName){

	formula = argv[0];  
    //used to fetch a formula from formula table and store it in the formula string
    return 0;
}

int callbackfields(void *NotUsed, int argc, char **argv, char **azColName){

    for(int i=0; i<argc; i++)
    {   
        fields[k] = argv[i];        
        k++;
        //fetches each field from formula fields table and stores them in a string array fields[]
    }
   return 0;
}


int main(void)
{	
    sqlite3 *db;
    char *zErrMsg = 0;

    // Save the result of opening the file
    int rc;

    // Save any SQL
    string sql,sqlsec;

    // Save the result of opening the file
    rc = sqlite3_open("mydb.db", &db);
    
    if(rc){
        // Show an error message
        cout << "DB Error: " << sqlite3_errmsg(db) << endl;
        // Close the connection
        sqlite3_close(db);
        // Return an error
        return(1);
    }
 
    
    
    cout<<"\n\n___________________________________________________\n";
    cout<<"\n       DISPLAYING ALL THE TABLES IN DATABASE\n";
    cout<<"___________________________________________________\n\n";
    cout<<"\nTABLE FORMULAE\n\n";
    sql = "SELECT * FROM 'formulae'"; 
    rc = sqlite3_exec(db, sql.c_str(), callback, 0, &zErrMsg);
    
    cout<<"\nTABLE FORMULAFIELDS\n\n";
    sql = "SELECT * FROM 'formulafields'"; 
    rc = sqlite3_exec(db, sql.c_str(), callback, 0, &zErrMsg);
    
    cout<<"\nTABLE SALARY\n\n";
    sql = "SELECT * FROM 'salary'"; 
    rc = sqlite3_exec(db, sql.c_str(), callback, 0, &zErrMsg);
    
    
    cout<<"___________________________________________________\n\n";
    
    char x;
	cout<<"Enter formula id : ";
	cin>>x;
    
    sql = "SELECT formula FROM 'formulae' where id = "; //query stored in string sql
    sql.push_back(x);
    sql.push_back(';');     //append fromula id taken from user and ; at the end of query string sql
                            //generates complete query.

    cout<<endl<<"Executed query : "<<sql<<endl;
    rc = sqlite3_exec(db, sql.c_str(), callbackformula, 0, &zErrMsg);
	cout<<endl<<"fetched : "<<formula;  //Query executed, formula fetched and stored in string formula    

	int n = formula.length();
    char formarray[n + 1];  // declaring character array
    strcpy(formarray, formula.c_str()); //converting formula string to character array
	
    /*Scanning the fetched formula through formarray*/
	YY_BUFFER_STATE buffer = yy_scan_string(formarray);

    if(yyparse()==0)
	{
		cout<<"\nPARSE SUCCESSFUL!\n";
        
        cout<<"\n___________________________________________________\n\n";
        cout<<"Now moving to replacing variables\n";

       
        //fetching all formula fields and storing in string array fields[]
        sqlsec = "SELECT ColumnName FROM formulafields;";
		rc = sqlite3_exec(db, sqlsec.c_str(), callbackfields, 0, &zErrMsg);
        
        string newstr="";   //This will store the new formula as string 
                            //having variables replaced with actual formula fields 

        for(int i=0; i<formula.length(); i++)
        {
            char ch = formula.at(i);
            if(ch!='<')
            {
               newstr.push_back(ch); //push all characters until '<' is encountered
            }
            else{
                //when '<' is encountered
                
                //variable is <Ax> where x is its tuple id
                //suppose i == '<', then tuple id x = i+2 ; as a character
                int index = formula.at(i+2); 
                index=index-48;   //changing x from character to integer, subtracting ascii difference  

                index--;    //since array indexing starts from 0

                newstr.append(fields[index]); //appends the actual field names (salary.basic etc) to new formula
                i+=3;   //skipping till '>' and then start reading after that
            }
        }
        
        cout<<endl<<"New formula with replaced variables is : "<<newstr;


        cout<<"\n___________________________________________________\n\n";
        cout<<"Enter salary id to be selected: ";
        cin>>x;
        string sel="SELECT (", rest=") AS RESULT FROM salary WHERE id=";
        sel.append(newstr);
        sel.append(rest);
        sel.push_back(x);
        cout<<"\n\nFinal Query will be : "<<endl<<endl<<sel<<endl<<endl;

        rc = sqlite3_exec(db, sel.c_str(), callback, 0, &zErrMsg);
        //query is executed and result displayed from callback() function
	}



	else
	{   //Parse fail
        cout<<"Session Terminated.";
	    exit(0);
	}


	yy_delete_buffer(buffer);
	
	sqlite3_close(db);
    return 0;

}
