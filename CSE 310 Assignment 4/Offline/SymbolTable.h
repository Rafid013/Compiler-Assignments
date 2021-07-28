#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <string>
#include <vector>
#include <stack>
#include "TypeMacros.h"


using namespace std;


class SymbolInfo{
    string symbolName;
    string symbolType;
    int iValue;
    float fValue;
    int *arriValue;
    float *arrfValue;
    bool isArray;
    bool isFunc;
    bool declared;
    bool defined;
    int arraySize;
    vector<SymbolInfo*> parameter;
    stack<int> usedIndices;
    int returnType; 
    int storedType;
public:
    SymbolInfo *next;
    string code;
    string asmSymbolName;
    SymbolInfo(string symbolName, string symbolType){
	this->symbolName = symbolName;
        this->symbolType = symbolType;
	isArray = isFunc = false;
	declared = defined = false;
        code = "";
    }
    void setName(string symbolName){
        this->symbolName = symbolName;
    }
    void setLastUsedIndex(int i) { usedIndices.push(i); }
    void setType(string symbolType){
        this->symbolType = symbolType;
    }
    void setStoredType(int type) { storedType = type; } 
    void setArraySize(int size) { 
	isArray = true;
	arraySize = size;
    }
    void setReturnType(int returnType){
	this->returnType = returnType;
	isFunc = true;
    }
    void setParameter(vector<SymbolInfo*> *parameter){
	this->parameter = *parameter;
	int size = (*parameter).size();
    }
    void setDeclared(bool v) { declared = v; } 
    void setDefined(bool v) { defined = v; } 
    bool setValue(int value) { 
	if(storedType == INT_VAL) { 
		iValue = value;
		return true;
	}
	return false; 
    }
    bool setValue(float value) { 
	if(storedType == FLOAT_VAL) { 
		fValue = value;
		return true;
	}
	return false; 
    }
    bool setValue(int value, int index) {
	if(storedType == INT_VAL && index < arraySize) {
		arriValue[index] = value;
		return true;
	}
	return false;
    }
    bool setValue(float value, int index) {
	if(storedType == FLOAT_VAL && index < arraySize) {
		arrfValue[index] = value;
		return true;
	}
	return false;
    }
    void initializeArray() {
	if(storedType == INT_VAL) arriValue = new int[arraySize];
	else if(storedType == FLOAT_VAL) arrfValue = new float[arraySize];
    }
    string getName(){
        return symbolName;
    }
    string getType(){
        return symbolType;
    }
    int getStoredType(){
    	return storedType;
    }
    int getLastUsedIndex() {
	int t = usedIndices.top();
	usedIndices.pop();
	return t;
    }
    float getfValue() {
    	return fValue;
    }
    float getfValue(int index) {
    	return arrfValue[index];
    }
    int getiValue() {
	return iValue;
    }
    int getiValue(int index) {
   	return arriValue[index];
    }
    int getArraySize() { return arraySize; }
    int getReturnType() { return returnType; }
    vector<SymbolInfo*> getParameters() { return parameter; } 
    bool checkArray() { return isArray; }
    bool checkFunc() { return isFunc; }
    bool checkDeclared() { return declared; }
    bool checkDefined() { return defined; }
};

class ScopeTable{
    SymbolInfo **hashtable;
    int numberOfBuckets;
    int ID;
    int lastBucket, lastIndex; //for insert, delete, look up tracking
public:
    ScopeTable *parentScope;
    ScopeTable(int n, int ID){
        hashtable = new SymbolInfo*[numberOfBuckets = n];
        for(int i = 0; i < n; ++i){
            hashtable[i] = NULL;
        }
        this->ID = ID;
        parentScope = NULL;
    }
    ~ScopeTable(){
        for(int i = 0; i < numberOfBuckets; ++i){
            SymbolInfo *temp, *current = hashtable[i];
            while(current){
                temp = current;
                current = current->next;
                delete temp;
            }
        }
        delete[]hashtable;
    }
    bool Insert(SymbolInfo *symbolInfo){
        int Size = symbolInfo->getName().size();
        int key = 0;
        for(int i = 0; i < Size; ++i){
            key += (int)symbolInfo->getName().at(i);
        }
        int h = (423*key + 212)%numberOfBuckets;
        lastBucket = h;
        if(!hashtable[h]){
            hashtable[h] = symbolInfo;
            hashtable[h]->next = NULL;
            lastIndex = 0;
            return true;
        }
        SymbolInfo *ltemp = hashtable[h];
        SymbolInfo *prev;
        lastIndex = 0;
        while(ltemp){
            if(ltemp->getName() == symbolInfo->getName()){ return false; }
            prev = ltemp;
            ltemp = ltemp->next;
            lastIndex++;
        }
        prev->next = symbolInfo;
        prev->next->next = NULL;
        return true;
    }
    SymbolInfo* LookUp(string symbolName){
        int Size = symbolName.size();
        int key = 0;
        for(int i = 0; i < Size; ++i){
            key += (int)symbolName.at(i);
        }
        int h = (423*key + 212)%numberOfBuckets;
        SymbolInfo *ltemp = hashtable[h];
        lastBucket = h;
        lastIndex = 0;
        while(ltemp){
            if(ltemp->getName() == symbolName) return ltemp;
            ltemp = ltemp->next;
            ++lastIndex;
        }
        return NULL;
    }
    bool Delete(string symbolName){
        int Size = symbolName.size();
        int key = 0;
        for(int i = 0; i < Size; ++i){
            key += (int)symbolName.at(i);
        }
        int h = (423*key + 212)%numberOfBuckets;
        lastBucket = h;
        SymbolInfo *ltemp = hashtable[h];
        if(!ltemp) return false;
        if(ltemp->getName() == symbolName){
            hashtable[h] = ltemp->next;
            lastIndex = 0;
            delete ltemp;
            return true;
        }
        lastIndex = 1;
        ltemp = ltemp->next;
        SymbolInfo *prev = ltemp;
        while(ltemp){
            if(ltemp->getName() == symbolName){
                SymbolInfo *temp = ltemp;
                prev->next = ltemp->next;
                delete ltemp;
                return true;
            }
            prev = ltemp;
            ltemp = ltemp->next;
            ++lastIndex;
        }
        return false;
    }
    void Print(){
        cout << "ScopeTable # " << ID << endl;
        for(int i = 0; i < numberOfBuckets; ++i){
            SymbolInfo *temp = hashtable[i];
            if(temp){
                cout << i << " -->  ";
                while(temp){
                    cout << "< " << temp->getName() << ", " << temp->getType() << " >  ";
                    temp = temp->next;
                }
                cout << endl << endl;
            }
        }
    }
    void PrintInFile(FILE *file){
	fprintf(file, "ScopeTable # %d\n\n", ID);
        for(int i = 0; i < numberOfBuckets; ++i){
            SymbolInfo *temp = hashtable[i];
            if(temp){
                fprintf(file, "%d -->  ", i);
                while(temp){
	            if(!temp->checkArray()) {
			    if(temp->getStoredType() == INT_VAL)
		            	fprintf(file, "<%s, %s, %d> ", (temp->getName()).c_str(), (temp->getType()).c_str(), temp->getiValue());
			    else fprintf(file, "<%s, %s, %f> ", (temp->getName()).c_str(), (temp->getType()).c_str(), temp->getfValue());
		    }
		    else {
			    fprintf(file, "<%s, %s, { ", (temp->getName()).c_str(), (temp->getType()).c_str());
                            int i;
			    if(temp->getStoredType() == INT_VAL) {
				for(i = 0; i < temp->getArraySize() - 1; ++i) {
					fprintf(file, "%d, ", temp->getiValue(i));
                                }
				fprintf(file, "%d }> ", temp->getiValue(i));
                            }
                            else {
				for(i = 0; i < temp->getArraySize() - 1; ++i) {
					fprintf(file, "%f, ", temp->getfValue(i));
                                }
                                fprintf(file, "%f }> ", temp->getfValue(i));
                            }
    		    }
                    temp = temp->next;
                }
                fprintf(file, "\n\n");
            }
        }
    }
    int getID(){
        return ID;
    }
    int getLastBucket(){ return lastBucket; }
    int getLastIndex(){ return lastIndex; }
};




class SymbolTable{
    ScopeTable *currentScope;
    int numberOfBuckets;
    int ID, bucket, index; //for insert, delete, look up tracking
    int scopeID;
    int lookedUpID;
public:
    SymbolTable(int n){
        numberOfBuckets = n;
        currentScope = new ScopeTable(n, 1);
        currentScope->parentScope = NULL;
	scopeID = lookedUpID = 1;
    }
    ~SymbolTable(){
        ScopeTable *temp = currentScope;
        while(temp){
            temp = temp->parentScope;
            delete temp;
        }
    }
    void EnterScope(){
	//printf("%d\n", scopeID);
        ScopeTable *newtable = new ScopeTable(numberOfBuckets, ++scopeID);
        newtable->parentScope = currentScope;
        currentScope = newtable;
        //ID = currentScope->getID();
   }
    bool ExitScope(){
        if(currentScope){
            ScopeTable *temp = currentScope;
            currentScope = currentScope->parentScope;
            delete temp;
            return true;
        }
        return false;
    }
    bool Insert(SymbolInfo *symbolInfo){
	bool temp = currentScope->Insert(symbolInfo);
        ID = currentScope->getID();
        bucket = currentScope->getLastBucket();
        index = currentScope->getLastIndex();
        return temp;
    }
    bool Remove(string symbolName){
        bool temp = currentScope->Delete(symbolName);
        ID = currentScope->getID();
        bucket = currentScope->getLastBucket();
        index = currentScope->getLastIndex();
        return temp;
    }
    SymbolInfo* LookUp(string symbolName){
        ScopeTable *temp = currentScope;
        while(temp){
            SymbolInfo *res = temp->LookUp(symbolName);
            if(res){
                lookedUpID = temp->getID();
                bucket = temp->getLastBucket();
                index = temp->getLastIndex();
                return res;
            }
            temp = temp->parentScope;
        }
        return NULL;
    }
    void PrintCurrentScopeTable(){
        currentScope->Print();
    }
    void PrintAllScopeTable(){
        ScopeTable *temp = currentScope;
        while(temp){
            temp->Print();
            temp = temp->parentScope;
        }
    }
    void PrintCurrentScopeTableFile(FILE *file){
        currentScope->PrintInFile(file);
    }
    void PrintAllScopeTableFile(FILE *file){
        ScopeTable *temp = currentScope;
        while(temp){
            temp->PrintInFile(file);
            temp = temp->parentScope;
        }
    }
    int getID(){
        return currentScope->getID();
    }
    int getLookedUpID() { return lookedUpID; }
    int getAffectedBucket(){ return bucket; }
    int getAffectedIndex(){ return index; }
};









