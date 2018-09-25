#!/usr/bin/env python2
#barcode_fasta_generator.py
#Caryn McCowan
################################################################################
#This code inputs a fasta file and outputs a smaller fasta file based on user input
#I wrote this tool to select barcodes used in a sequencing project as input for a demultiplexing script
################################################################################

def input_to_list(input_string):
    print input_string
    input_parsed = input_string.split(" ")
    mylist = []
    for word in input_parsed:
        mylist.append(word)

    return mylist

################################################################################
def make_new_fasta_dictionary(mylist, fasta_dictionary):

    output_dict = {}

    for target in mylist:
        if target not in fasta_dictionary:
            print "--> your sequence name " + target + " is not present in your FASTA file"
        else:
            #search for target name in FASTA header
            for name, sequence in fasta_dictionary.items():
                if str(target) in str(name):
                    output_dict[name] = sequence


    return output_dict

################################################################################
def dictionary_to_fasta(file_name, input_dictionary):
    output_dict = {}

    new_file = open(file_name, "a")

    for name, sequence in input_dictionary.items():
        new_file.write(">" + name + "\n")
        new_file.write(sequence + "\n")

    new_file.close()
    return new_file

################################################################################

class FastaTool:
    def __init__(self, myfastafile):
        import os
        self.filename = myfastafile
        self.filepath = os.path.abspath(str(myfastafile))

    #method that turns a FASTA file into a dictionary
    def fastaTodictionary(self):
        #open and read fasta file
        myfasta = open (self.filename, 'r')
        #create an empty fasta dictionary
        myfastadictionary = {}
        #iterate through file
        for line in myfasta: #each line is a string
            if line.startswith('>'):
                fastaheader = line.strip('>').rstrip('\n')  #'>' and newlines need to be removed
                fastasequence = "" #create a new sequence string for each sequence
            else:
                fastasequence = fastasequence + line.rstrip('\n')
                myfastadictionary[fastaheader] = fastasequence

        return myfastadictionary  #returns a dictionary

################################################################################

# Main program
import time

#prompt the user for input files
print "\n***Welcome to the FASTA barcode selector****\n\n"
print "...please input the entire path to your input fasta file:\n"
input_fasta = raw_input("-->")
print "\n"
print "...please enter the full names of your barcodes, separated by spaces\n"
desired_barcodes_string = raw_input("-->")
print "\n"
print "...please enter the entire path of your output fasta\n"
out_file = raw_input("-->")
print "\n"

#call the various functions
barcode_fasta = FastaTool(input_fasta)
barcode_dict = barcode_fasta.fastaTodictionary()
input_list = input_to_list(desired_barcodes_string)
input_sequence_dictionary = make_new_fasta_dictionary(input_list, barcode_dict)
output_fasta_file = dictionary_to_fasta(out_file, input_sequence_dictionary)

#output results
time.sleep(1)
print "\n***program complete***\n"
time.sleep(0.5)
print "the following sequences were written to your output fasta file:\n\n"
for id, sequence in input_sequence_dictionary.items():
    print id + " --> " + sequence
print "\n\n"
time.sleep(0.5)
print "***your FASTA barcode file is at the following path:\n"
print "--> " + out_file
