#!/usr/bin/env ruby


# So we generate the pngs, then write an HTML file of the output images
# open up https://fengyuanchen.github.io/cropper/ with the images and
# highlight each region that has text. We OCR all those locations and produce
# the "expected input". It doesn't matter if the OCR is slightly off,
# as long as it is stable.

# From there it's easy to generate a collection of arguments to a test program
# that can be invoked however


# https://github.com/wvanbergen/chunky_png
# use this for getting pixel data

# this gem might have support for extracting text more directly. It requires old ruby so
# it may not be a great choice
# https://github.com/tardate/pdf-reader-turtletext

# Tesseract is a dependency of this code
# http://blog.matt-swain.com/post/26419042500/installing-tesseract-ocr-on-mac-os-x-lion
# http://stackoverflow.com/questions/32179402/tesseract-ocr-gem-issue-on-mac-os-x


# Not working? Getting ImageMagic errors?
# ghostscript is a dependency of imagemagick
# https://superuser.com/questions/819277/cant-convert-pdf-into-image-because-of-no-images-defined-error

require 'fileutils'
require 'securerandom'

# Takes a PDF and extracts text from regions in the doc
class TextInPDFRegion
  def initialize(pdf_file_name)
    @prefix = SecureRandom.hex

    Dir.mkdir('tmp') unless Dir.exist?('tmp')

    # http://stackoverflow.com/questions/6605006/convert-pdf-to-image-with-high-resolution
    `magick -density 300 #{pdf_file_name} tmp/interim-#{@prefix}.png`
    @interim_images = Dir["tmp/interim-#{@prefix}-*.png"]
  end

  def words(page, width, height, x_offset, y_offset)
    `magick tmp/interim-#{@prefix}-#{page}.png -crop #{width}x#{height}+#{x_offset}+#{y_offset} tmp/out-#{@prefix}.png`
    `tesseract tmp/out-#{@prefix}.png tmp/output-#{@prefix} -l eng >/dev/null 2>&1`
    file = File.open("tmp/output-#{@prefix}.txt")
    file.read.chomp('')
  ensure
    FileUtils.rm "tmp/out-#{@prefix}.png"
    FileUtils.rm "tmp/output-#{@prefix}.txt"
  end

  def teardown
    FileUtils.rm @interim_images
  end
end

pdf = TextInPDFRegion.new(ARGV[0])

# ./validate.rb stackoverflow.pdf 0 1200 80 750 50
# ocr_text = pdf.words(*ARGV[1..-1])

ocr_text = pdf.words(0, 1200, 80, 750, 50)

# Yeah, it's weird that it's putting extra spaces, but whatever. The point
# is that it's stable. This should work.
if ocr_text == 'Convert PDF to J PG or PN G using C# or Command Line - Stack Overﬂow'
  puts "🎉"
end

pdf.teardown
