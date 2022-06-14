local measures = {}

measures.measurelist = {} -- length of each measure in lines
measures.noteinfo = {} -- key is the note, value is the line in the measure the note is on

function measures.reset()
	measures.measurelist = {}
	measures.noteinfo = {}
end

function measures.set(idx,cnt)
	measures.measurelist[idx]=cnt
end

function measures.addnote(note, line)
	measures.noteinfo[note] = line
end

function measures.getmeasure(idx)
	return measures.measurelist[idx] or measures.measurelist[#measures.measurelist]
end

function measures.getmeasureatbeat(beat)
	return measures.getmeasure(math.floor(beat/4))
end

return measures