// typedef Server#() ModExpt

module mkModExpt(ModExpt);

  interface Put request = toPut(infifo);
  interface Get response = toGet(outfifo);
endmodule

module mkModExptTest (Empty);
  // some unit test
endmodule

