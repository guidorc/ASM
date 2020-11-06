#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <ctype.h>
#include <string.h>
#include <assert.h>
#include <math.h>
#include <stdbool.h>

#include "lib.h"

char* strings[10] = {"una","eternidad","esperé","este","instante","gracias","totales","me","verás","volver"};
float numeros[5] = {0.0f, 1.0f, 1.0f, 2.0f, 3.0f};

void test_floats(FILE *pfile) {
    fprintf(pfile, "===== Floats =====\n");
    float f1 = 4.20f;
    float f2 = 4.20f;
    fprintf(pfile, "res = %i \n", floatCmp(&f1, &f2));
}

void test_strings(FILE *pfile) {
    fprintf(pfile,"===== String =====\n");
    char *a, *b, *c;
    // clone
    fprintf(pfile,"==> Clone\n");
    a = strClone("casa");
    b = strClone("");
    strPrint(a,pfile);
    fprintf(pfile,"\n");
    strPrint(b,pfile);
    fprintf(pfile,"\n");
    strDelete(a);
    strDelete(b);
    // cmp
    fprintf(pfile,"==> Cmp\n");
    char* texts[5] = {"aa","bb","dd","ff","00"};
    for(int i=0; i<5; i++) {
        for(int j=0; j<5; j++) {
            fprintf(pfile,"cmp(%s,%s) -> %i\n",texts[i],texts[j],strCmp(texts[i],texts[j]));
        }
    }
}



void test_document(FILE *pfile) {
    fprintf(pfile,"===== Documento =====\n");
    int dato1 = 9;
    int dato2 = 12;
    float float_1 = 2.018f;
    float float_2 = 1.618f;
    document_t* doc = docNew(6, TypeInt, &dato1, TypeInt, &dato2, TypeFloat, &float_1, TypeFloat, &float_2, TypeString, "just", TypeString, "do it");
    document_t* doc_clon = docClone(doc);   // Rompe en tester
    docPrint(doc, pfile);
    fprintf(pfile,"\n");
    docPrint(doc_clon, pfile);
    fprintf(pfile,"\n");
    docDelete(doc);
    docDelete(doc_clon);
}

void test_list(FILE *pfile){
    fprintf(pfile,"===== Lista =====\n");
    list_t* l_str = listNew(TypeString);
    for (int i = 0; i < 10; ++i) {
        listAdd(l_str, strClone(strings[i]));   // Si no hacemos strClone, se rompe listDelete
    }
    listPrint(l_str, pfile);
    list_t* l_float = listNew(TypeFloat);
    for (int i = 0; i < 5; ++i)
    {
        listAdd(l_float, floatClone(&numeros[i]));
    }
    list_t* l_str_clone = listClone(l_str);
    list_t* l_float_clone = listClone(l_float);
    listPrint(l_str, pfile);
    fprintf(pfile,"\n");
    listPrint(l_float_clone, pfile);
    listRemove(l_str, strings[0]);
    listDelete(l_str);
    listDelete(l_str_clone);
    listDelete(l_float);
    listDelete(l_float_clone);
}


void test_tree(FILE *pfile){
    fprintf(pfile,"===== Arbol =====\n");

    int intA;

    tree_t* arbol = treeNew(TypeInt, TypeString, 1);
    intA = 24; treeInsert(arbol, &intA, "papanatas");
    intA = 34; treeInsert(arbol, &intA, "rima");
    intA = 24; treeInsert(arbol, &intA, "buscabullas");
    intA = 11; treeInsert(arbol, &intA, "musica");
    intA = 31; treeInsert(arbol, &intA, "Pikachu");
    intA = 11; treeInsert(arbol, &intA, "Bulbasaur");
    intA = -2; treeInsert(arbol, &intA, "Charmander");

    tree_t* arbol_inv = treeNew(TypeInt, TypeString, 1);
    intA = -2; treeInsert(arbol_inv, &intA, "Charmander");
    intA = 11; treeInsert(arbol_inv, &intA, "Bulbasaur");
    intA = 31; treeInsert(arbol_inv, &intA, "Pikachu");
    intA = 11; treeInsert(arbol_inv, &intA, "musica");
    intA = 24; treeInsert(arbol_inv, &intA, "buscabullas");
    intA = 34; treeInsert(arbol_inv, &intA, "rima");
    intA = 24; treeInsert(arbol_inv, &intA, "papanatas");

    treePrint(arbol, pfile);
    fprintf(pfile,"\n");
    treePrint(arbol_inv, pfile);

    treeDelete(arbol);
    treeDelete(arbol_inv);
}


int main (void){
    FILE *pfile = fopen("salida.caso.propios.txt","w");
    test_floats(pfile);
    test_strings(pfile);
    test_document(pfile);
    test_list(pfile);
    test_tree(pfile);
    fclose(pfile);
    return 0;
}
