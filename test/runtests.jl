using QuantumCitations
using Documenter
using Test


@testset "tex2unicode" begin
    @test QuantumCitations.tex2unicode("-- ---") == "– —"
    @test QuantumCitations.tex2unicode(
        raw"\`{o}\'{o}\^{o}\~{o}\={o}\u{o}\.{o}\\\"{o}\r{a}\H{o}\v{s}\d{u}\c{c}\k{a}\b{b}\~{a}") == "òóôõōŏȯöåőšụçąḇã"
    @test QuantumCitations.tex2unicode(
        raw"\i{}\o{}\O{}\l{}\L{}\i\o\O\l\L") == "ıøØłŁıøØłŁ"
    @test QuantumCitations.tex2unicode(
        raw"\t{oo}{testText}\t{az}") == "o͡otestTexta͡z"
    @test QuantumCitations.tex2unicode(
        raw"{\o}verline") == "øverline"
    @test QuantumCitations.tex2unicode(
        raw"\t{oo}\\\"{\i}{abcdefg}") == "o͡oïabcdefg"
    @test_skip QuantumCitations.tex2unicode(
        raw"{abcd\~{o}efg}") == "abcdõefg"
    @test QuantumCitations.tex2unicode(
        raw"\overline") == "\\overline"
end

@testset "doctest fix" begin
    # verify https://github.com/ali-ramadhan/DocumenterCitations.jl/issues/55 is fixed
    doctest(QuantumCitations; fix=true)
end
