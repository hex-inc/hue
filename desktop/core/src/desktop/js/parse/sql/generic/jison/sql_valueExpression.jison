// Licensed to Cloudera, Inc. under one
// or more contributor license agreements.  See the NOTICE file
// distributed with this work for additional information
// regarding copyright ownership.  Cloudera, Inc. licenses this file
// to you under the Apache License, Version 2.0 (the
// "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

ValueExpression
 : 'NOT' ValueExpression
   {
     // verifyType($2, 'BOOLEAN');
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2);
   }
 | '!' ValueExpression
   {
     // verifyType($2, 'BOOLEAN');
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2);
   }
 | '~' ValueExpression
   {
     $$ = $2;
     parser.extractExpressionText($$, $1, $2);
   }
 | '-' ValueExpression %prec NEGATION
   {
     // verifyType($2, 'NUMBER');
     $$ = $2;
     $2.types = ['NUMBER'];
     parser.extractExpressionText($$, $1, $2);
   }
 | ValueExpression 'IS' OptionalNot 'NULL'
   {
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3, $4);
   }
 | ValueExpression 'IS' OptionalNot 'TRUE'
   {
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3, $4);
   }
 | ValueExpression 'IS' OptionalNot 'FALSE'
   {
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3, $4);
   }
 | ValueExpression 'IS' OptionalNot 'DISTINCT' 'FROM' ValueExpression
   {
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3, $4, $5, $6);
   }
 ;

ValueExpression_EDIT
 : 'NOT' ValueExpression_EDIT                           -> { types: [ 'BOOLEAN' ], suggestFilters: $2.suggestFilters }
 | 'NOT' 'CURSOR'
   {
     parser.suggestFunctions();
     parser.suggestColumns();
     parser.suggestKeywords(['EXISTS']);
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | '!' ValueExpression_EDIT                             -> { types: [ 'BOOLEAN' ], suggestFilters: $2.suggestFilters }
 | '!' AnyCursor
   {
     parser.suggestFunctions({ types: [ 'BOOLEAN' ] });
     parser.suggestColumns({ types: [ 'BOOLEAN' ] });
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | '~' ValueExpression_EDIT                             -> { types: [ 'T' ], suggestFilters: $2.suggestFilters }
 | '~' 'PARTIAL_CURSOR'
   {
     parser.suggestFunctions();
     parser.suggestColumns();
     $$ = { types: [ 'T' ] };
   }
 | '-' ValueExpression_EDIT %prec NEGATION
   {
     if (!$2.typeSet) {
       parser.applyTypeToSuggestions({ types: ['NUMBER'] });
     }
     $$ = { types: [ 'NUMBER' ], suggestFilters: $2.suggestFilters };
   }
 | '-' 'PARTIAL_CURSOR' %prec NEGATION
   {
     parser.suggestFunctions({ types: [ 'NUMBER' ] });
     parser.suggestColumns({ types: [ 'NUMBER' ] });
     $$ = { types: [ 'NUMBER' ] };
   }
 | ValueExpression 'IS' 'CURSOR'
   {
     parser.suggestKeywords(['FALSE', 'NOT NULL', 'NOT TRUE', 'NOT FALSE', 'NULL', 'TRUE']);
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'IS' 'NOT' 'CURSOR'
   {
     parser.suggestKeywords(['FALSE', 'NULL', 'TRUE']);
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'IS' OptionalNot 'DISTINCT' 'CURSOR'
   {
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'IS' 'CURSOR' 'NULL'
   {
     parser.suggestKeywords(['NOT']);
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'IS' 'CURSOR' 'FALSE'
   {
     parser.suggestKeywords(['NOT']);
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'IS' 'CURSOR' 'TRUE'
   {
     parser.suggestKeywords(['NOT']);
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'IS' OptionalNot 'DISTINCT' 'FROM' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest($1, $3 ? 'IS NOT DISTINCT FROM' : 'IS DISTINCT FROM');
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'IS' OptionalNot 'DISTINCT' 'FROM' ValueExpression_EDIT
   {
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $6.suggestFilters }
   }
 ;

// ------------------  EXISTS and parenthesized ------------------
ValueExpression
 : 'EXISTS' TableSubQuery
   {
     $$ = { types: [ 'BOOLEAN' ] };
     // clear correlated flag after completed sub-query (set by lexer)
     parser.yy.correlatedSubQuery = false;
   }
 | '(' ValueExpression ')'                                -> $2
 ;

ValueExpression_EDIT
 : 'EXISTS' TableSubQuery_EDIT                               -> { types: [ 'BOOLEAN' ] }
 | '(' ValueExpression_EDIT RightParenthesisOrError
   {
     $$ = $2;
   }
 | '(' 'CURSOR' RightParenthesisOrError
   {
     parser.valueExpressionSuggest();
     $$ = { types: ['T'], typeSet: true };
   }
 ;

// ------------------  COMPARISON ------------------

ValueExpression
 : ValueExpression '=' ValueExpression
   {
     parser.addColRefToVariableIfExists($1, $3);
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 | ValueExpression '<' ValueExpression
   {
     parser.addColRefToVariableIfExists($1, $3);
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 | ValueExpression '>' ValueExpression
   {
     parser.addColRefToVariableIfExists($1, $3);
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 | ValueExpression 'COMPARISON_OPERATOR' ValueExpression
   {
     parser.addColRefToVariableIfExists($1, $3);
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 ;

ValueExpression_EDIT
 : 'CURSOR' '=' ValueExpression
   {
     parser.valueExpressionSuggest($3, $2);
     parser.applyTypeToSuggestions($3);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true };
   }
 | 'CURSOR' '<' ValueExpression
   {
     parser.valueExpressionSuggest($3, $2);
     parser.applyTypeToSuggestions($3);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | 'CURSOR' '>' ValueExpression
   {
     parser.valueExpressionSuggest($3, $2);
     parser.applyTypeToSuggestions($3);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | 'CURSOR' 'COMPARISON_OPERATOR' ValueExpression
   {
     parser.valueExpressionSuggest($3, $2);
     parser.applyTypeToSuggestions($3);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | ValueExpression_EDIT '=' ValueExpression
   {
     if (!$1.typeSet) {
       parser.applyTypeToSuggestions($3);
       parser.addColRefIfExists($3);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression_EDIT '<' ValueExpression
   {
     if (!$1.typeSet) {
       parser.applyTypeToSuggestions($3);
       parser.addColRefIfExists($3);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression_EDIT '>' ValueExpression
   {
     if (!$1.typeSet) {
       parser.applyTypeToSuggestions($3);
       parser.addColRefIfExists($3);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression_EDIT 'COMPARISON_OPERATOR' ValueExpression
   {
     if (!$1.typeSet) {
       parser.applyTypeToSuggestions($3);
       parser.addColRefIfExists($3);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression '=' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest($1, $2);
     parser.applyTypeToSuggestions($1);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | ValueExpression '<' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest($1, $2);
     parser.applyTypeToSuggestions($1);
     $$ = { types: [ 'BOOLEAN' ] , typeSet: true, endsWithLessThanOrEqual: true };
   }
 | ValueExpression '>' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest($1, $2);
     parser.applyTypeToSuggestions($1);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | ValueExpression 'COMPARISON_OPERATOR' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest($1, $2);
     parser.applyTypeToSuggestions($1);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true, endsWithLessThanOrEqual: $2 === '<='  };
   }
 | ValueExpression '=' ValueExpression_EDIT
   {
     if (!$3.typeSet) {
       parser.applyTypeToSuggestions($1);
       parser.addColRefIfExists($1);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $3.suggestFilters }
   }
 | ValueExpression '<' ValueExpression_EDIT
   {
     if (!$3.typeSet) {
       parser.applyTypeToSuggestions($1);
       parser.addColRefIfExists($1);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $3.suggestFilters }
   }
 | ValueExpression '>' ValueExpression_EDIT
   {
     if (!$3.typeSet) {
       parser.applyTypeToSuggestions($1);
       parser.addColRefIfExists($1);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $3.suggestFilters }
   }
 | ValueExpression 'COMPARISON_OPERATOR' ValueExpression_EDIT
   {
     if (!$3.typeSet) {
       parser.applyTypeToSuggestions($1);
       parser.addColRefIfExists($1);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $3.suggestFilters }
   }
 ;


// ------------------  IN ------------------

ValueExpression
 : ValueExpression 'NOT' 'IN' '(' TableSubQueryInner ')'   -> { types: [ 'BOOLEAN' ] }
 | ValueExpression 'NOT' 'IN' '(' ValueExpressionList ')'  -> { types: [ 'BOOLEAN' ] }
 | ValueExpression 'IN' '(' TableSubQueryInner ')'         -> { types: [ 'BOOLEAN' ] }
 | ValueExpression 'IN' '(' ValueExpressionList ')'        -> { types: [ 'BOOLEAN' ] }
 ;

ValueExpression_EDIT
 : ValueExpression 'NOT' 'IN' ValueExpressionInSecondPart_EDIT
   {
     if ($4.inValueEdit) {
       parser.valueExpressionSuggest($1, $2 + ' ' + $3);
       parser.applyTypeToSuggestions($1);
     }
     if ($4.cursorAtStart) {
       parser.suggestKeywords(['SELECT']);
     }
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | ValueExpression 'IN' ValueExpressionInSecondPart_EDIT
   {
     if ($3.inValueEdit) {
       parser.valueExpressionSuggest($1, $2);
       parser.applyTypeToSuggestions($1);
     }
     if ($3.cursorAtStart) {
       parser.suggestKeywords(['SELECT']);
     }
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | ValueExpression_EDIT 'NOT' 'IN' '(' ValueExpressionList RightParenthesisOrError  -> { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
 | ValueExpression_EDIT 'NOT' 'IN' '(' TableSubQueryInner RightParenthesisOrError   -> { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
 | ValueExpression_EDIT 'IN' '(' ValueExpressionList RightParenthesisOrError        -> { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
 | ValueExpression_EDIT 'IN' '(' TableSubQueryInner RightParenthesisOrError         -> { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
 ;

ValueExpressionInSecondPart_EDIT
 : '(' TableSubQueryInner_EDIT RightParenthesisOrError
 | '(' ValueExpressionList_EDIT RightParenthesisOrError -> { inValueEdit: true }
 | '(' AnyCursor RightParenthesisOrError                -> { inValueEdit: true, cursorAtStart: true }
 ;

// ------------------  BETWEEN ------------------

ValueExpression
 : ValueExpression 'NOT' 'BETWEEN' ValueExpression 'BETWEEN_AND' ValueExpression
   {
     $$ = { types: [ 'BOOLEAN' ] }
     parser.extractExpressionText($$, $1, $2, $3, $4, $5, $6);
   }
 | ValueExpression 'BETWEEN' ValueExpression 'BETWEEN_AND' ValueExpression
   {
     $$ = { types: [ 'BOOLEAN' ] }
     parser.extractExpressionText($$, $1, $2, $3, $4, $5);
   }
 ;

ValueExpression_EDIT
 : ValueExpression_EDIT 'NOT' 'BETWEEN' ValueExpression 'BETWEEN_AND' ValueExpression
   {
     if ($4.types[0] === $6.types[0] && !$1.typeSet) {
       parser.applyTypeToSuggestions($4);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters };
   }
 | ValueExpression 'NOT' 'BETWEEN' ValueExpression_EDIT 'BETWEEN_AND' ValueExpression
   {
     if ($1.types[0] === $6.types[0] && !$4.typeSet) {
       parser.applyTypeToSuggestions($1);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $4.suggestFilters };
   }
 | ValueExpression 'NOT' 'BETWEEN' ValueExpression 'BETWEEN_AND' ValueExpression_EDIT
   {
     if ($1.types[0] === $4.types[0] && !$6.typeSet) {
       parser.applyTypeToSuggestions($1);
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $6.suggestFilters };
   }
 | ValueExpression 'NOT' 'BETWEEN' ValueExpression 'BETWEEN_AND' 'CURSOR'
   {
     parser.valueExpressionSuggest($1, $5);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | ValueExpression 'NOT' 'BETWEEN' ValueExpression 'CURSOR'
   {
     parser.suggestValueExpressionKeywords($4, ['AND']);
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'NOT' 'BETWEEN' 'CURSOR'
   {
     parser.valueExpressionSuggest($1, $2 + ' ' + $3);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | ValueExpression_EDIT 'BETWEEN' ValueExpression 'BETWEEN_AND' ValueExpression
   {
     if ($1.types[0] === $3.types[0] && !$1.typeSet) {
       parser.applyTypeToSuggestions($1)
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters };
   }
 | ValueExpression 'BETWEEN' ValueExpression_EDIT 'BETWEEN_AND' ValueExpression
   {
     if ($1.types[0] === $3.types[0] && !$3.typeSet) {
       parser.applyTypeToSuggestions($1)
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $3.suggestFilters };
   }
 | ValueExpression 'BETWEEN' ValueExpression 'BETWEEN_AND' ValueExpression_EDIT
   {
     if ($1.types[0] === $3.types[0] && !$5.typeSet) {
       parser.applyTypeToSuggestions($1)
     }
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $5.suggestFilters };
   }
 | ValueExpression 'BETWEEN' ValueExpression 'BETWEEN_AND' 'CURSOR'
   {
     parser.valueExpressionSuggest($1, $4);
     parser.applyTypeToSuggestions($1);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true  };
   }
 | ValueExpression 'BETWEEN' ValueExpression 'CURSOR'
   {
     parser.suggestValueExpressionKeywords($3, ['AND']);
     $$ = { types: [ 'BOOLEAN' ] };
   }
 | ValueExpression 'BETWEEN' 'CURSOR'
   {
     parser.valueExpressionSuggest($1, $2);
     parser.applyTypeToSuggestions($1);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true };
   }
 ;

// ------------------  BOOLEAN ------------------

ValueExpression
 : ValueExpression 'OR' ValueExpression
   {
     // verifyType($1, 'BOOLEAN');
     // verifyType($3, 'BOOLEAN');
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 | ValueExpression 'AND' ValueExpression
   {
     // verifyType($1, 'BOOLEAN');
     // verifyType($3, 'BOOLEAN');
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 ;

ValueExpression_EDIT
 : 'CURSOR' 'OR' ValueExpression
   {
     parser.valueExpressionSuggest(undefined, $2);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true, suggestFilters: true };
   }
 | ValueExpression_EDIT 'OR' ValueExpression
   {
     parser.addColRefIfExists($3);
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression 'OR' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest(undefined, $2);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true, suggestFilters: true };
   }
 | ValueExpression 'OR' ValueExpression_EDIT
   {
     parser.addColRefIfExists($1);
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $3.suggestFilters }
   }
 | 'CURSOR' 'AND' ValueExpression
   {
     parser.valueExpressionSuggest(undefined, $2);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true, suggestFilters: true };
   }
 | ValueExpression_EDIT 'AND' ValueExpression
   {
     parser.addColRefIfExists($3);
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression 'AND' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest(undefined, $2);
     $$ = { types: [ 'BOOLEAN' ], typeSet: true, suggestFilters: true };
   }
 | ValueExpression 'AND' ValueExpression_EDIT
   {
     parser.addColRefIfExists($1);
     $$ = { types: [ 'BOOLEAN' ], suggestFilters: $3.suggestFilters }
   }
 ;

// ------------------  ARITHMETIC ------------------

ValueExpression
 : ValueExpression '-' ValueExpression
   {
     // verifyType($1, 'NUMBER');
     // verifyType($3, 'NUMBER');
     $$ = { types: [ 'NUMBER' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 | ValueExpression '*' ValueExpression
   {
     // verifyType($1, 'NUMBER');
     // verifyType($3, 'NUMBER');
     $$ = { types: [ 'NUMBER' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 | ValueExpression 'ARITHMETIC_OPERATOR' ValueExpression
   {
     // verifyType($1, 'NUMBER');
     // verifyType($3, 'NUMBER');
     $$ = { types: [ 'NUMBER' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 ;

ValueExpression_EDIT
 : 'CURSOR' '*' ValueExpression
   {
     parser.valueExpressionSuggest(undefined, $2);
     parser.applyTypeToSuggestions({ types: [ 'NUMBER' ] });
     $$ = { types: [ 'NUMBER' ], typeSet: true };
   }
 | 'CURSOR' 'ARITHMETIC_OPERATOR' ValueExpression
   {
     parser.valueExpressionSuggest(undefined, $2);
     parser.applyTypeToSuggestions({ types: [ 'NUMBER' ] });
     $$ = { types: [ 'NUMBER' ], typeSet: true };
   }
 | ValueExpression_EDIT '-' ValueExpression
   {
     if (!$1.typeSet) {
       parser.applyTypeToSuggestions({ types: ['NUMBER'] });
       parser.addColRefIfExists($3);
     }
     $$ = { types: [ 'NUMBER' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression_EDIT '*' ValueExpression
   {
     if (!$1.typeSet) {
       parser.applyTypeToSuggestions({ types: ['NUMBER'] });
       parser.addColRefIfExists($3);
     }
     $$ = { types: [ 'NUMBER' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression_EDIT 'ARITHMETIC_OPERATOR' ValueExpression
   {
     if (!$1.typeSet) {
       parser.applyTypeToSuggestions({ types: ['NUMBER'] });
       parser.addColRefIfExists($3);
     }
     $$ = { types: [ 'NUMBER' ], suggestFilters: $1.suggestFilters }
   }
 | ValueExpression '-' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest(undefined, $2);
     parser.applyTypeToSuggestions({ types: ['NUMBER'] });
     $$ = { types: [ 'NUMBER' ], typeSet: true };
   }
 | ValueExpression '*' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest(undefined, $2);
     parser.applyTypeToSuggestions({ types: ['NUMBER'] });
     $$ = { types: [ 'NUMBER' ], typeSet: true };
   }
 | ValueExpression 'ARITHMETIC_OPERATOR' PartialBacktickedOrAnyCursor
   {
     parser.valueExpressionSuggest(undefined, $2);
     parser.applyTypeToSuggestions({ types: ['NUMBER'] });
     $$ = { types: [ 'NUMBER' ], typeSet: true };
   }
 | ValueExpression '-' ValueExpression_EDIT
   {
     if (!$3.typeSet) {
       parser.applyTypeToSuggestions({ types: ['NUMBER'] });
       parser.addColRefIfExists($1);
     }
     $$ = { types: [ 'NUMBER' ], suggestFilters: $3.suggestFilters };
   }
 | ValueExpression '*' ValueExpression_EDIT
   {
     if (!$3.typeSet) {
       parser.applyTypeToSuggestions({ types: ['NUMBER'] });
       parser.addColRefIfExists($1);
     }
     $$ = { types: [ 'NUMBER' ], suggestFilters: $3.suggestFilters };
   }
 | ValueExpression 'ARITHMETIC_OPERATOR' ValueExpression_EDIT
   {
     if (!$3.typeSet) {
       parser.applyTypeToSuggestions({ types: ['NUMBER'] });
       parser.addColRefIfExists($1);
     }
     $$ = { types: [ 'NUMBER' ], suggestFilters: $3.suggestFilters };
   }
 ;

// ------------------  LIKE, RLIKE and REGEXP ------------------

ValueExpression
 : ValueExpression LikeRightPart
   {
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2);
   }
 | ValueExpression 'NOT' LikeRightPart
   {
     $$ = { types: [ 'BOOLEAN' ] };
     parser.extractExpressionText($$, $1, $2, $3);
   }
 ;

LikeRightPart
 : 'LIKE' ValueExpression
   {
     $$ = { suggestKeywords: ['NOT'] }
     parser.extractExpressionText($$, $1, $2);
   }
 | 'RLIKE' ValueExpression
   {
     $$ = { suggestKeywords: ['NOT'] }
     parser.extractExpressionText($$, $1, $2);
   }
 | 'REGEXP' ValueExpression
   {
     $$ = { suggestKeywords: ['NOT'] }
     parser.extractExpressionText($$, $1, $2);
   }
 ;

LikeRightPart_EDIT
 : 'LIKE' ValueExpression_EDIT
 | 'RLIKE' ValueExpression_EDIT
 | 'REGEXP' ValueExpression_EDIT
 | 'LIKE' PartialBacktickedOrCursor
   {
     parser.suggestFunctions({ types: [ 'STRING' ] });
     parser.suggestColumns({ types: [ 'STRING' ] });
     $$ = { types: ['BOOLEAN'] }
   }
 | 'RLIKE' PartialBacktickedOrCursor
   {
     parser.suggestFunctions({ types: [ 'STRING' ] });
     parser.suggestColumns({ types: [ 'STRING' ] });
     $$ = { types: ['BOOLEAN'] }
   }
 | 'REGEXP' PartialBacktickedOrCursor
   {
     parser.suggestFunctions({ types: [ 'STRING' ] });
     parser.suggestColumns({ types: [ 'STRING' ] });
     $$ = { types: ['BOOLEAN'] }
   }
 ;

ValueExpression_EDIT
 : ValueExpression_EDIT LikeRightPart               -> { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
 | ValueExpression_EDIT 'NOT' LikeRightPart         -> { types: [ 'BOOLEAN' ], suggestFilters: $1.suggestFilters }
 | ValueExpression LikeRightPart_EDIT               -> { types: [ 'BOOLEAN' ] }
 | ValueExpression 'NOT' LikeRightPart_EDIT         -> { types: [ 'BOOLEAN' ] }
 | 'CURSOR' LikeRightPart
   {
     parser.valueExpressionSuggest(undefined, $2);
     parser.applyTypeToSuggestions({ types: [ 'STRING' ] });
     $$ = { types: [ 'BOOLEAN' ], typeSet: true };
   }
 | 'CURSOR' 'NOT' LikeRightPart
   {
     parser.valueExpressionSuggest(undefined, $2 + ' ' + $3);
     parser.applyTypeToSuggestions({ types: [ 'STRING' ] });
     $$ = { types: [ 'BOOLEAN' ], typeSet: true };
   }
 ;

// ------------------  CASE, WHEN, THEN ------------------

ValueExpression
 : 'CASE' CaseRightPart
   {
     $$ = $2;
     parser.extractExpressionText($$, $1, $2);
   }
 | 'CASE' ValueExpression CaseRightPart
   {
     $$ = $3;
     parser.extractExpressionText($$, $1, $2, $3);
   }
 ;

ValueExpression_EDIT
 : 'CASE' CaseRightPart_EDIT                         -> $2
 | 'CASE' 'CURSOR' EndOrError
   {
     parser.valueExpressionSuggest();
     parser.suggestKeywords(['WHEN']);
     $$ = { types: [ 'T' ], typeSet: true };
   }
 | 'CASE' ValueExpression CaseRightPart_EDIT         -> $3
 | 'CASE' ValueExpression 'CURSOR' EndOrError
   {
     parser.suggestValueExpressionKeywords($2, ['WHEN']);
     $$ = { types: [ 'T' ], typeSet: true };
   }
 | 'CASE' ValueExpression_EDIT CaseRightPart
    {
      $$ = $3;
      $$.suggestFilters = $2.suggestFilters;
    }
 | 'CASE' ValueExpression_EDIT EndOrError            -> { types: [ 'T' ], suggestFilters: $2.suggestFilters }
 | 'CASE' 'CURSOR' CaseRightPart                     -> { types: [ 'T' ] }
 ;

CaseRightPart
 : CaseWhenThenList 'END'
   {
     $$ = parser.findCaseType($1)
     parser.extractExpressionText($$, $1, $2);
   }
 | CaseWhenThenList 'ELSE' ValueExpression 'END'
   {
     $1.caseTypes.push($3);
     $$ = parser.findCaseType($1);
     parser.extractExpressionText($$, $1, $2, $3, $4);
   }
 ;

CaseRightPart_EDIT
 : CaseWhenThenList_EDIT EndOrError                            -> parser.findCaseType($1)
 | CaseWhenThenList 'ELSE' ValueExpression 'CURSOR'
   {
     parser.suggestValueExpressionKeywords($3, ['END']);
     $1.caseTypes.push($3);
     $$ = parser.findCaseType($1);
   }
 | CaseWhenThenList_EDIT 'ELSE' ValueExpression EndOrError
   {
     $1.caseTypes.push($3);
     $$ = parser.findCaseType($1);
   }
 | CaseWhenThenList_EDIT 'ELSE' EndOrError                      -> parser.findCaseType($1)
 | CaseWhenThenList 'CURSOR' ValueExpression EndOrError
   {
     if ($4.toLowerCase() !== 'end') {
       parser.suggestValueExpressionKeywords($1, [{ value: 'END', weight: 3 }, { value: 'ELSE', weight: 2 }, { value: 'WHEN', weight: 1 }]);
     } else {
       parser.suggestValueExpressionKeywords($1, [{ value: 'ELSE', weight: 2 }, { value: 'WHEN', weight: 1 }]);
     }
     $$ = parser.findCaseType($1);
   }
 | CaseWhenThenList 'CURSOR' EndOrError
   {
     if ($3.toLowerCase() !== 'end') {
       parser.suggestValueExpressionKeywords($1, [{ value: 'END', weight: 3 }, { value: 'ELSE', weight: 2 }, { value: 'WHEN', weight: 1 }]);
     } else {
       parser.suggestValueExpressionKeywords($1, [{ value: 'ELSE', weight: 2 }, { value: 'WHEN', weight: 1 }]);
     }
     $$ = parser.findCaseType($1);
   }
 | CaseWhenThenList 'ELSE' ValueExpression_EDIT EndOrError
   {
     $1.caseTypes.push($3);
     $$ = parser.findCaseType($1);
     $$.suggestFilters = $3.suggestFilters
   }
 | CaseWhenThenList 'ELSE' 'CURSOR' EndOrError
   {
     parser.valueExpressionSuggest();
     $$ = parser.findCaseType($1);
   }
 | 'ELSE' 'CURSOR' EndOrError
   {
     parser.valueExpressionSuggest();
     $$ = { types: [ 'T' ], typeSet: true };
   }
 | 'CURSOR' 'ELSE' ValueExpression EndOrError
   {
     parser.valueExpressionSuggest();
     parser.suggestKeywords(['WHEN']);
     $$ = $3;
   }
 | 'CURSOR' 'ELSE' EndOrError
   {
     parser.valueExpressionSuggest();
     parser.suggestKeywords(['WHEN']);
     $$ = { types: [ 'T' ] };
   }
 ;

EndOrError
 : 'END'
 | error
 ;

CaseWhenThenList
 : CaseWhenThenListPartTwo
   {
     $$ = { caseTypes: [ $1 ], lastType: $1 }
     parser.extractExpressionText($$, $1);
   }
 | CaseWhenThenList CaseWhenThenListPartTwo
   {
     $1.caseTypes.push($2);
     $$ = { caseTypes: $1.caseTypes, lastType: $2 };
     parser.extractExpressionText($$, $1, $2);
   }
 ;

CaseWhenThenList_EDIT
 : CaseWhenThenListPartTwo_EDIT
 | CaseWhenThenList CaseWhenThenListPartTwo_EDIT
 | CaseWhenThenList CaseWhenThenListPartTwo_EDIT CaseWhenThenList
 | CaseWhenThenList 'CURSOR' CaseWhenThenList
   {
     parser.suggestValueExpressionKeywords($1, ['WHEN']);
   }
 | CaseWhenThenListPartTwo_EDIT CaseWhenThenList                   -> $2
 ;

CaseWhenThenListPartTwo
 : 'WHEN' ValueExpression 'THEN' ValueExpression
   {
     $$ = $4
     parser.extractExpressionText($$, $1, $2, $3, $4);
   }
 ;

CaseWhenThenListPartTwo_EDIT
 : 'WHEN' ValueExpression_EDIT                         -> { caseTypes: [{ types: ['T'] }], suggestFilters: $2.suggestFilters }
 | 'WHEN' ValueExpression_EDIT 'THEN'                  -> { caseTypes: [{ types: ['T'] }], suggestFilters: $2.suggestFilters }
 | 'WHEN' ValueExpression_EDIT 'THEN' ValueExpression  -> { caseTypes: [$4], suggestFilters: $2.suggestFilters }
 | 'WHEN' ValueExpression 'THEN' ValueExpression_EDIT  -> { caseTypes: [$4], suggestFilters: $4.suggestFilters }
 | 'WHEN' 'THEN' ValueExpression_EDIT                  -> { caseTypes: [$3], suggestFilters: $3.suggestFilters }
 | 'CURSOR' ValueExpression 'THEN'
   {
     parser.suggestKeywords(['WHEN']);
     $$ = { caseTypes: [{ types: ['T'] }] };
   }
 | 'CURSOR' ValueExpression 'THEN' ValueExpression
   {
     parser.suggestKeywords(['WHEN']);
     $$ = { caseTypes: [$4] };
   }
 | 'CURSOR' 'THEN'
   {
     parser.valueExpressionSuggest();
     parser.suggestKeywords(['WHEN']);
     $$ = { caseTypes: [{ types: ['T'] }] };
   }
 | 'CURSOR' 'THEN' ValueExpression
    {
      parser.valueExpressionSuggest();
      parser.suggestKeywords(['WHEN']);
      $$ = { caseTypes: [{ types: ['T'] }] };
    }
 | 'WHEN' 'CURSOR'
   {
     parser.valueExpressionSuggest();
     $$ = { caseTypes: [{ types: ['T'] }], suggestFilters: true };
   }
 | 'WHEN' 'CURSOR' ValueExpression
   {
     parser.valueExpressionSuggest();
     parser.suggestKeywords(['THEN']);
     $$ = { caseTypes: [{ types: ['T'] }], suggestFilters: true };
   }
 | 'WHEN' 'CURSOR' 'THEN'
   {
     parser.valueExpressionSuggest();
     $$ = { caseTypes: [{ types: ['T'] }], suggestFilters: true };
   }
 | 'WHEN' 'CURSOR' 'THEN' ValueExpression
   {
     parser.valueExpressionSuggest();
     $$ = { caseTypes: [$4], suggestFilters: true };
   }
 | 'WHEN' ValueExpression 'CURSOR'
   {
     parser.suggestValueExpressionKeywords($2, ['THEN']);
     $$ = { caseTypes: [{ types: ['T'] }] };
   }
 | 'WHEN' ValueExpression 'CURSOR' ValueExpression
   {
     parser.suggestValueExpressionKeywords($2, ['THEN']);
     $$ = { caseTypes: [{ types: ['T'] }] };
   }
 | 'WHEN' ValueExpression 'THEN' 'CURSOR'
   {
     parser.valueExpressionSuggest();
     $$ = { caseTypes: [{ types: ['T'] }] };
   }
 | 'WHEN' ValueExpression 'THEN' 'CURSOR' ValueExpression
   {
     parser.valueExpressionSuggest();
     $$ = { caseTypes: [{ types: ['T'] }] };
   }
 | 'WHEN' 'THEN' 'CURSOR' ValueExpression
   {
     parser.valueExpressionSuggest();
     $$ = { caseTypes: [{ types: ['T'] }] };
   }
 | 'WHEN' 'THEN' 'CURSOR'
   {
     parser.valueExpressionSuggest();
     $$ = { caseTypes: [{ types: ['T'] }] };
   }
 ;

// ------------------  :: CASTS  --------------------

PrimitiveTypeOrError
 : PrimitiveType
 | error
 ;

ValueExpression
 : ValueExpression '::' PrimitiveType
  {
    parser.extractExpressionText($$, $1, $2, $3);
    $$ = { types: [ $3.toUpperCase() ] }
  }
 ;

ValueExpression_EDIT
 : ValueExpression '::' AnyCursor
  {
    parser.suggestKeywords(parser.getTypeKeywords());
    $$ = { types: [ 'T' ] };
  }
 | ValueExpression_EDIT '::' PrimitiveTypeOrError
  {
    parser.addColRefIfExists($1);
    $$ = { types: [ $3.toUpperCase() ] }
  }
 ;
