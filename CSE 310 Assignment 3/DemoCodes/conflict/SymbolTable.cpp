#include <iostream>
#include <cstdlib>
#include <cstdio>
#include <string>
#include <fstream>
using namespace std;


class SymbolInfo{
    string symbolName;
    string symbolType;
public:
    SymbolInfo *next;
    void setName(string symbolName){
        this->symbolName = symbolName;
    }
    void setType(string symbolType){
        this->symbolType = symbolType;
    }
    string getName(){
        return symbolName;
    }
    string getType(){
        return symbolType;
    }
};

class ScopeTable{
    SymbolInfo **hashtable;
    static int ID_Count;
    int numberOfBuckets;
    int ID;
    int lastBucket, lastIndex; //for insert, delete, look up tracking
public:
    ScopeTable *parentScope;
    ScopeTable(int n){
        hashtable = new SymbolInfo*[numberOfBuckets = n];
        for(int i = 0; i < n; ++i){
            hashtable[i] = NULL;
        }
        ID = ++ID_Count;
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
    bool Insert(string symbolName, string symbolType){
        int Size = symbolName.size();
        int key = 0;
        for(int i = 0; i < Size; ++i){
            key += (int)symbolName.at(i);
        }
        int h = (423*key + 212)%numberOfBuckets;
        lastBucket = h;
        if(!hashtable[h]){
            hashtable[h] = new SymbolInfo;
            hashtable[h]->setName(symbolName);
            hashtable[h]->setType(symbolType);
            hashtable[h]->next = NULL;
            lastIndex = 0;
            return true;
        }
        SymbolInfo *ltemp = hashtable[h];
        SymbolInfo *prev;
        lastIndex = 0;
        while(ltemp){
            if(ltemp->getName() == symbolName) return false;
            prev = ltemp;
            ltemp = ltemp->next;
            lastIndex++;
        }
        prev->next = new SymbolInfo;
        prev->next->setName(symbolName);
        prev->next->setType(symbolType);
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
                    fprintf(file, "<%s, %s> ", (temp->getName()).c_str(), (temp->getType()).c_str());
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

int ScopeTable::ID_Count = 0;


class SymbolTable{
    ScopeTable *currentScope;
    int numberOfBuckets;
    int ID, bucket, index; //for insert, delete, look up tracking
public:
    SymbolTable(int n){
        numberOfBuckets = n;
        currentScope = new ScopeTable(n);
        currentScope->parentScope = NULL;
    }
    ~SymbolTable(){
        ScopeTable *temp = currentScope;
        while(temp){
            temp = temp->parentScope;
            delete temp;
        }
    }
    void EnterScope(){
        ScopeTable *newtable = new ScopeTable(numberOfBuckets);
        newtable->parentScope = currentScope;
        currentScope = newtable;
        ID = currentScope->getID();
   }
    bool ExitScope(){
        if(currentScope){
            ScopeTable *temp = currentScope;
            ID = currentScope->getID();
            currentScope = currentScope->parentScope;
            delete temp;
            return true;
        }
        return false;
    }
    bool Insert(string symbolName, string symbolType){
        bool temp = currentScope->Insert(symbolName, symbolType);
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
                ID = temp->getID();
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
    int getAffectedID(){
        return ID;
    }
    int getAffectedBucket(){ return bucket; }
    int getAffectedIndex(){ return index; }
};
