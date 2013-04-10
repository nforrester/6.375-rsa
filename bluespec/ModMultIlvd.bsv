// typedef Server#() ModMultIlvd

module mkModMultIlvd(ModMultIlvd);

  interface Put request = toPut(infifo);
  interface Get response = toGet(outfifo);
endmodule

module mkModMultIlvdTest (Empty);
  // some unit test
endmodule

